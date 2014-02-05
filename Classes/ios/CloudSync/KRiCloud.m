//
//  KRiCloud.m
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRiCloud.h"

static NSString* createUUID()
{
	CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
	
	NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject);
	
	CFUUIDGetUUIDBytes(uuidObject);
	CFRelease(uuidObject);
	
	return uuidStr;
}

@implementation KRiCloudContext
@end

@interface KRiCloud()
@property (nonatomic) NSMutableSet* startDownloadURLs;
@end

@implementation KRiCloud

+(KRiCloud*)sharedInstance{
	static KRiCloud* cloud = nil;
	if(cloud == nil){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            cloud = [[KRiCloud alloc] init];
        });
	}
	
	return cloud;
}

-(KRiCloud*)init{
	self = [super init];
	if(self){
		_presentedItemURL = nil;
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			NSFileManager* fileManager = [NSFileManager defaultManager];
			NSURL* url = [fileManager URLForUbiquityContainerIdentifier:nil];
			dispatch_async(dispatch_get_main_queue(), ^{
				_presentedItemURL = url;
			});
		});
		
		_query = [[NSMetadataQuery alloc] init];
		[_query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(queryDidUpdateNotification:)
													 name:NSMetadataQueryDidUpdateNotification
												   object:_query];

		_queryContexts = [NSMutableDictionary dictionaryWithCapacity:3];
		_startDownloadURLs = [NSMutableSet setWithCapacity:5];
		
		_presentedItemOperationQueue = [[NSOperationQueue alloc] init];
		[_presentedItemOperationQueue setName:[NSString stringWithFormat:@"presenter queue -- %@", self]];
		[_presentedItemOperationQueue setMaxConcurrentOperationCount:1];
		
		[NSFileCoordinator addFilePresenter:self];
		_shouldUpdateQuery = YES;
	}
	return self;
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidUpdateNotification
                                                  object:_query];

	[NSFileCoordinator removeFilePresenter:self];
	
	[_query disableUpdates];
    [_query stopQuery];
	_query = nil;

	_presentedItemURL = nil;
	_queryContexts = nil;
	_presentedItemOperationQueue = nil;
}

#pragma mark - loadFiles
-(BOOL)loadFilesWithPredicate:(NSPredicate*)predicate completedBlock:(KRiCloudCompletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;

	if([_query isStarted] && !_shouldUpdateQuery){
		block(_query, nil);
		return YES;
	}
	
	[_query setPredicate:predicate];
	// fetch the percent-downloaded key when updating results
	[_query setValueListAttributes:@[NSMetadataUbiquitousItemPercentDownloadedKey,
										NSMetadataUbiquitousItemIsDownloadedKey]];
	
	
	__block id notificationId = nil;
	typedef void (^notificationObserver_block)(NSNotification *);
	notificationObserver_block notification_block = ^(NSNotification* note){
		_shouldUpdateQuery = NO;
		if(block){
			[_query disableUpdates];
			
			block(_query, nil);
			
			[_query enableUpdates];
		}
		
		[[NSNotificationCenter defaultCenter] removeObserver:notificationId];
	};
	
	notificationId = [[NSNotificationCenter defaultCenter] addObserverForName:NSMetadataQueryDidFinishGatheringNotification
													  object:_query
													   queue:[NSOperationQueue mainQueue]
												  usingBlock:notification_block];
	[_query startQuery];
	
	return YES;
}

-(void)startDownloadUsingBlock:(NSMetadataQuery*)query
				 progressBlock:(KRiCloudProgressBlock)block{
	_progressBlock = block;

	NSFileManager* fileManager = [NSFileManager defaultManager];
	for(NSMetadataItem* item in [query results]) {
		NSNumber* isDownloaded  = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
		if([isDownloaded boolValue])
			continue;
		
		NSURL* url = [item valueForAttribute:NSMetadataItemURLKey];
		NSError* error = nil;
		if([fileManager startDownloadingUbiquitousItemAtURL:url error:&error]){
			if(block){
				[self.startDownloadURLs addObject:url];
				block(url, 0.f);
			}
		}
	}
}

-(void)startDownloadWithURLsUsingBlock:(NSArray*)URLs
						 progressBlock:(KRiCloudProgressBlock)block{
	_progressBlock = block;

	NSFileManager* fileManager = [NSFileManager defaultManager];
	for(NSURL* url in URLs){
		for(NSMetadataItem* item in [_query results]) {
			if(![url isEqual:[item valueForAttribute:NSMetadataItemURLKey]])
				continue;
			
			NSNumber* isDownloaded  = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
			if([isDownloaded boolValue])
				break;
			
			NSError* error = nil;
			if([fileManager startDownloadingUbiquitousItemAtURL:url error:&error]){
				if(block){
					[self.startDownloadURLs addObject:url];
					block(url, 0.f);
				}
			}
			break;
		}
	}
}

-(void)queryDidUpdateNotification:(NSNotification*)notification{
	if(!_progressBlock)
		return;
	
	NSMetadataQuery* query = [notification object];
	[query disableUpdates];
	
	for(NSMetadataItem* item in [query results]){
		NSURL* url = [item valueForAttribute:NSMetadataItemURLKey];
		NSNumber* isDownloaded  = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
		if([isDownloaded boolValue] &&
					[self.startDownloadURLs containsObject:url]){
			_progressBlock(url, 100.f);
			[self.startDownloadURLs removeObject:url];
			continue;
		}
		if([isDownloaded boolValue])
			continue;
		
		NSNumber* downloading = [item valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
		float download = [downloading doubleValue];
		if(0.f<download){
			_progressBlock(url, download);
			
			if(![self.startDownloadURLs containsObject:url]){
				[self.startDownloadURLs addObject:url];
			}
			
			if(100.f<=download)
				[self.startDownloadURLs removeObject:url];
		}else{
			NSLog(@"Update Item on iCloud:%@", url);

			NSError* error = nil;
			NSFileManager* fileManager = [NSFileManager defaultManager];
			[fileManager startDownloadingUbiquitousItemAtURL:url error:&error];
		}
	}

	[query enableUpdates];
}

-(void)queryDidProgressNotification:(NSNotification*)notification{
//	NSMetadataQuery* query = [notification object];
//	NSLog(@"queryDidProgressNotification - newQuery:%@, count:%d", query, [query resultCount]);
}

-(void)raiseCompletedBlock:(KRiCloudContext*)context{
	NSMetadataQuery* query = context.query;
	context.block(query, nil);
}

#pragma mark - monitorFiles
-(BOOL)monitorFilesWithPredicate:(NSPredicate*)predicate completedBlock:(KRiCloudCompletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
	
	NSMetadataQuery* query = [[NSMetadataQuery alloc] init];
	[query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
	[query setPredicate:predicate];
	
	KRiCloudContext* context = [[KRiCloudContext alloc]init];
	context.query = query;
	context.block = block;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(monitorFilesQueryDidUpdateNotification:)
												 name:NSMetadataQueryDidUpdateNotification
											   object:query];
	
	[query startQuery];
	
	NSValue* value = [NSValue valueWithNonretainedObject:query];
	[_queryContexts setObject:context forKey:value];
	return YES;
}

-(void)monitorFilesQueryDidUpdateNotification:(NSNotification *)notification {
	NSMetadataQuery* query = [notification object];
    [query disableUpdates];
    [query stopQuery];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSMetadataQueryDidUpdateNotification
                                                  object:query];
    
	NSValue* value = [NSValue valueWithNonretainedObject:query];
	KRiCloudContext* context = [_queryContexts objectForKey:value];
    [self raiseCompletedBlock:context];
	
	[_queryContexts removeObjectForKey:query];
}

#pragma mark - batch sync
-(BOOL)batchLockAndSync:(NSArray*)readingURLs toLocalURLs:(NSArray*)toLocalURLs
			writingURLs:(NSArray*)writingURLs fromLocalURLs:(NSArray*)fromLocalURLs
				  error:(NSError**)outError
		 completedBlock:(KRiCloudBatchSyncCompeletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
	
	NSAssert([readingURLs count]==[toLocalURLs count], @"Must be equal");
	NSAssert([writingURLs count]==[fromLocalURLs count], @"Must be equal");
	if([readingURLs count]!=[toLocalURLs count])
		return NO;
	if([writingURLs count]!=[fromLocalURLs count])
		return NO;
	
#ifdef DEBUG
	if([readingURLs count])
		NSLog(@"readingURLs:%@", readingURLs);
	if([writingURLs count])
		NSLog(@"writingURLs:%@", writingURLs);
#endif
	
	NSMutableArray* toLocalErrors = [NSMutableArray arrayWithCapacity:[readingURLs count]];
	NSMutableArray* fromLocalErrors = [NSMutableArray arrayWithCapacity:[writingURLs count]];
	
	NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc]initWithFilePresenter:self];
	[fileCoordinator prepareForReadingItemsAtURLs:readingURLs options:NSFileCoordinatorReadingWithoutChanges
							   writingItemsAtURLs:writingURLs options:NSFileCoordinatorWritingForReplacing
											error:outError
									   byAccessor:^(void(^prepareCompletionHandler)(void)){
										   
										   [self batchSync:fileCoordinator
											   readingURLs:readingURLs toLocalURLs:toLocalURLs toLocalErrors:toLocalErrors
											   writingURLs:writingURLs fromLocalURLs:fromLocalURLs fromLocalErrors:fromLocalErrors];
										   
										   block(readingURLs, toLocalErrors, fromLocalURLs, fromLocalErrors);
									   }];
	
	return YES;
}

-(void)batchSync:(NSFileCoordinator*)fileCoordinator
	 readingURLs:(NSArray*)readingURLs toLocalURLs:(NSArray*)toLocalURLs toLocalErrors:(NSMutableArray*)toLocalErrors
	 writingURLs:(NSArray*)writingURLs fromLocalURLs:(NSArray*)fromLocalURLs fromLocalErrors:(NSMutableArray*)fromLocalErrors{
	
	NSUInteger count = [readingURLs count];
	for(NSUInteger i=0; i<count; i++){
		NSError* error = nil;
		BOOL ret = [self saveToDocumentWithFileCoordinator:fileCoordinator
												  url:[readingURLs objectAtIndex:i]
									   destinationURL:[toLocalURLs objectAtIndex:i]
												error:&error];
		if(!ret || [error code])
			[toLocalErrors addObject:error];
		else
			[toLocalErrors addObject:[NSNull null]];
	}
	NSAssert([toLocalURLs count] == [toLocalErrors count], @"Must be equl");
	
	count = [writingURLs count];
	for(NSUInteger i=0; i<count; i++){
		NSError* error = nil;
		BOOL ret = [self saveToUbiquityContainerWithFileCoordinator:fileCoordinator
																url:[fromLocalURLs objectAtIndex:i]
													 destinationURL:[writingURLs objectAtIndex:i]
															  error:&error];
		if(!ret || [error code])
			[fromLocalErrors addObject:error];
		else
			[fromLocalErrors addObject:[NSNull null]];
	}
	NSAssert([fromLocalURLs count] == [fromLocalErrors count], @"Must be equl");
}

#pragma mark - enable/disable update
-(void)enableUpdate{
	[_query enableUpdates];
}

-(void)disableUpdate{
	[_query disableUpdates];
}

#pragma mark - save
-(BOOL)saveToUbiquityContainer:(id)key url:(NSURL*)url destinationURL:(NSURL*)destinationURL completedBlock:(KRiCloudSaveFileCompletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;

	NSError* error = nil;
    NSFileCoordinator* fc = [[NSFileCoordinator alloc] initWithFilePresenter:self];
	return [self saveToUbiquityContainerWithFileCoordinator:fc url:url destinationURL:destinationURL error:&error];
}

-(BOOL)saveToUbiquityContainerWithFileCoordinator:(NSFileCoordinator*)fileCoordinator url:(NSURL*)url destinationURL:(NSURL*)destinationURL error:(NSError**)error{
	__block NSError* innerError = nil;
	__block BOOL ret = NO;
	NSError* outError = nil;
    [fileCoordinator coordinateWritingItemAtURL:destinationURL
										options:NSFileCoordinatorWritingForReplacing
										  error:&outError
									 byAccessor:^(NSURL *updatedURL) {
										 ret = [self copyFile:url toURL:updatedURL error:&innerError];
										 if(ret){
											 [fileCoordinator itemAtURL:url didMoveToURL:updatedURL];
										 }
									 }];
	if([outError code]){
		*error = outError;
		return NO;
	}
	if(!ret){
		*error = innerError;
		return NO;
	}
	
    return YES;
}


-(BOOL)copyFile:(NSURL*)url toURL:(NSURL*)toURL error:(NSError**)outError{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	BOOL ret = NO;
	if([fileManager fileExistsAtPath:[toURL path]]){
		NSURL* tempUrl = [NSURL fileURLWithPath:[self tempFilePath]];
		ret = [fileManager copyItemAtURL:url toURL:tempUrl error:outError];
		if(ret)
			ret = [fileManager replaceItemAtURL:toURL withItemAtURL:tempUrl backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&toURL error:outError];
	}else{
		ret = [fileManager copyItemAtURL:url toURL:toURL error:outError];
	}
	return ret;
}

-(NSString*)tempFilePath{
	NSString* uuid = createUUID();
	NSString* tempDirectory = NSTemporaryDirectory();
	return [tempDirectory stringByAppendingPathComponent:uuid];
}

-(BOOL)saveToDocument:(id)key url:(NSURL*)url destinationURL:(NSURL*)destinationURL completedBlock:(KRiCloudSaveFileCompletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
	
	NSError* error = nil;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	[fileManager startDownloadingUbiquitousItemAtURL:url error:&error];
//	NSLog(@"startDownloadingUbiquitousItemAtURL - ret:%@, error:%@", ret?@"YES":@"NO", error);

    NSFileCoordinator* fc = [[NSFileCoordinator alloc] initWithFilePresenter:self];
	return [self saveToDocumentWithFileCoordinator:fc url:url destinationURL:destinationURL error:&error];
}

-(BOOL)saveToDocumentWithFileCoordinator:(NSFileCoordinator*)fileCoordinator
									 url:(NSURL*)url
						  destinationURL:(NSURL*)destinationURL
								   error:(NSError**)error{
	__block NSError* innerError = nil;
	NSError* outError = nil;
/*
	NSFileManager* fileManager = [NSFileManager defaultManager];
	BOOL ret = [fileManager startDownloadingUbiquitousItemAtURL:url error:&outError];
	
	NSLog(@"startDownloadingUbiquitousItemAtURL -\nurl:%@\nret:%@, error:%@", url, ret?@"YES":@"NO", outError);
	if(NO==ret){
		*error = outError;
		return ret;
	}
*/

/*
	for(NSMetadataItem *item in [_query results]){
		NSURL* remoteURL = [item valueForAttribute:NSMetadataItemURLKey];
		if(![url isEqual:remoteURL])
			continue;
		
		NSLog(@"Download status:%@", url);
		NSNumber* isDownloading = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
		NSNumber* isDownloaded  = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
		NSNumber* perDownloading = [item valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
		
		NSLog(@"isDownloaded=%@", [isDownloaded boolValue]?@"Yes":@"No");
		NSLog(@"isDownloading=%@", [isDownloading boolValue]?@"Yes":@"No");
		NSLog(@"percent downloaded=%f", [perDownloading doubleValue]);
		
		while(![isDownloaded boolValue]){
			isDownloaded  = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
			perDownloading = [item valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
			NSLog(@"percent downloaded=%f", [perDownloading doubleValue]);
			sleep(1);
		}
		break;
	}

	
	NSFileManager* fileManager = [NSFileManager defaultManager];
	while(![fileManager fileExistsAtPath:[url path]])
		sleep(1);
	
	NSLog(@"--------- Now file exists:%@", url);
*/
    [fileCoordinator coordinateReadingItemAtURL:url
										options:NSFileCoordinatorReadingWithoutChanges
										  error:&outError
									 byAccessor:^(NSURL *updatedURL) {
#ifdef DEBUG
										 BOOL ret = [self copyFile:updatedURL toURL:destinationURL error:&innerError];
										 NSLog(@"copyFile-url:%@, ret:%@", updatedURL, ret?@"YES":@"NO");
#elif DEBUG
										 [self copyFile:updatedURL toURL:destinationURL error:&innerError];
#endif
									 }];
	if([outError code]){
		*error = outError;
		return NO;
	}
	if([innerError code]){
		*error = innerError;
		return NO;
	}
	
    return YES;
}




#pragma mark - rename File
-(void)renameFileUsingBlock:(NSString*)fileName
					newName:(NSString*)newFileName
					  block:(KRiCloudResultBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return;
	
	if(![_query isStarted] || 0==[_query resultCount]){
		block(NO, [self createFileNotFoundError:fileName]);
		return;
	}
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		NSError* error = nil;
		BOOL ret = NO;
		for(NSMetadataItem* item in [_query results]){
			NSURL* fileURL = [item valueForAttribute:NSMetadataItemURLKey];
			NSString* name = [fileURL lastPathComponent];
			if(![fileName isEqualToString:name])
				continue;

			NSURL* newURL = [fileURL URLByDeletingLastPathComponent];
			newURL = [newURL URLByAppendingPathComponent:newFileName];
			
			ret = [self renameFile:fileURL newURL:newURL error:&error];
			break;
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			block(ret, error);
		});
	});
}

-(NSError*)createFileNotFoundError:(NSString*)path{
	NSString* fileNotFound = [NSString stringWithFormat:@"File not found - file:%@", path];
	NSMutableDictionary* details = [NSMutableDictionary dictionary];
	[details setValue:fileNotFound forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"com.mindhd.iCloud" code:404 userInfo:details];
}

-(BOOL)renameFile:(NSURL*)sourceURL
		   newURL:(NSURL*)destinationURL
			error:(NSError**)error{
	NSError* outError = nil;
	__block BOOL result = NO;
	NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateWritingItemAtURL:sourceURL
										options:NSFileCoordinatorWritingForMoving
										  error:&outError
									 byAccessor:^(NSURL *newURL) {
										 NSFileManager* fileManager = [NSFileManager defaultManager];
										 result = [fileManager moveItemAtURL:newURL toURL:destinationURL error:error];
										 if(result)
											 [fileCoordinator itemAtURL:newURL didMoveToURL:destinationURL];
									 }];
	if([outError code]){
		*error = outError;
		return NO;
	}
	
    return result;
}

#pragma mark - remove file
-(BOOL)removeFile:(NSString*)fileName completedBlock:(KRiCloudRemoveFileCompletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", NSMetadataItemFSNameKey, fileName];
	
	[self loadFilesWithPredicate:predicate
				  completedBlock:^(NSMetadataQuery* query, NSError* error){
					  if([query resultCount])
						  [self removeFilesWithItems:[query results] block:block];
				  }];
	return YES;
}

-(BOOL)removeAllFiles:(KRiCloudRemoveFileCompletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K like '*')", NSMetadataItemFSNameKey];
	
	[self loadFilesWithPredicate:predicate
				  completedBlock:^(NSMetadataQuery* query, NSError* error){
		  [self removeFilesWithItems:[query results] block:block];
	}];

	return YES;
}

-(BOOL)removeFilesWithItems:(NSArray*)metadataItems block:(KRiCloudRemoveFileCompletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		for(NSMetadataItem *item in metadataItems){
			NSURL* fileURL = [item valueForAttribute:NSMetadataItemURLKey];
			
			NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
			[fileCoordinator coordinateWritingItemAtURL:fileURL
												options:NSFileCoordinatorWritingForDeleting
												  error:nil
											 byAccessor:^(NSURL* writingURL) {
												 NSError* error = nil;
												 NSFileManager* fileManager = [[NSFileManager alloc] init];
												 BOOL result = [fileManager removeItemAtURL:writingURL error:&error];
												 if([error code]){
													 block(NO, error);
													 return;
												 }
												 
												 if(result){
													 [fileCoordinator itemAtURL:writingURL didMoveToURL:nil];
												 }
			}];
		}
		
		block(YES, nil);
	});
	
	return YES;
}

#pragma mark NSFilePresenter protocol

- (NSURL *)presentedItemURL{
	if(!_presentedItemURL){
		NSFileManager* fileManager = [NSFileManager defaultManager];
		_presentedItemURL = [fileManager URLForUbiquityContainerIdentifier:nil];
	}
	
//	NSLog(@"NSFilePresenter-presentedItemURL:%@", _presentedItemURL);
	return _presentedItemURL;
}

- (NSOperationQueue *)presentedItemOperationQueue{
//	NSLog(@"NSFilePresenter-presentedItemOperationQueue");
    return _presentedItemOperationQueue;
}

- (void)relinquishPresentedItemToReader:(void (^)(void (^reacquirer)(void))) reader{
//	NSLog(@"NSFilePresenter-relinquishPresentedItemToReader");
	[_query disableUpdates];
	
	reader(^{
//		NSLog(@"NSFilePresenter-relinquishPresentedItemToReader - enable");
		[_query enableUpdates];
	});
}
- (void)relinquishPresentedItemToWriter:(void (^)(void (^reacquirer)(void)))writer;{
//	NSLog(@"NSFilePresenter-relinquishPresentedItemToWriter");
	[_query disableUpdates];
	
	writer(^{
//		NSLog(@"NSFilePresenter-relinquishPresentedItemToWriter - enable");
		[_query enableUpdates];
	});
}

- (void)savePresentedItemChangesWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler{
//    NSLog(@"NSFilePresenter-savePresentedItemChangesWithCompletionHandler");
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler{
//    NSLog(@"NSFilePresenter-accommodatePresentedItemDeletionWithCompletionHandler");
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL;{
//    NSLog(@"NSFilePresenter-presentedItemDidMoveToURL: %@", newURL);
	_presentedItemURL = newURL;
}

// This gets called for local coordinated writes and for unsolicited incoming edits from iCloud. From the header, "Your NSFileProvider may be sent this message without being sent -relinquishPresentedItemToWriter: first. Make your application do the best it can in that case."
- (void)presentedItemDidChange;{
//    NSLog(@"NSFilePresenter-presentedItemDidChange");
}

- (void)presentedItemDidGainVersion:(NSFileVersion *)version;{
//    NSLog(@"NSFilePresenter-presentedItemDidGainVersion");
}

- (void)presentedItemDidLoseVersion:(NSFileVersion *)version;{
//    NSLog(@"NSFilePresenter-presentedItemDidLoseVersion");
}

- (void)presentedItemDidResolveConflictVersion:(NSFileVersion *)version;{
//    NSLog(@"NSFilePresenter-presentedItemDidResolveConflictVersion");
}

- (void)presentedSubitemAtURL:(NSURL *)url didGainVersion:(NSFileVersion *)version{
//	NSLog(@"NSFilePresenter-presentedSubitemAtURL-url:%@, didGainVersion:%@", url, version);
}

- (void)presentedSubitemAtURL:(NSURL *)url didLoseVersion:(NSFileVersion *)version{
//	NSLog(@"NSFilePresenter-presentedSubitemAtURL-url:%@, didLoseVersion:%@", url, version);
}

- (void)presentedSubitemAtURL:(NSURL *)url didResolveConflictVersion:(NSFileVersion *)version{
//	NSLog(@"NSFilePresenter-presentedSubitemAtURL-url:%@, didResolveConflictVersion:%@", url, version);
}

- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError *errorOrNil))completionHandler{
//	NSLog(@"NSFilePresenter-accommodatePresentedSubitemDeletionAtURL-url:%@", url);
	completionHandler(nil);
}

- (void)presentedSubitemDidAppearAtURL:(NSURL *)url{
//	NSLog(@"NSFilePresenter-presentedSubitemDidAppearAtURL:%@", url);
}

- (void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL{
//	NSLog(@"NSFilePresenter-presentedSubitemAtURL - oldURL:%@, didMoveToURL:%@", oldURL, newURL);
}

- (void)presentedSubitemDidChangeAtURL:(NSURL *)url{
//	NSLog(@"NSFilePresenter-presentedSubitemDidChangeAtURL:%@", url);
	// remove a file that has named of url, then sync again.
	
	_shouldUpdateQuery = YES;
	if([_delegate respondsToSelector:@selector(iCloudItemDidChanged:URL:)])
		[_delegate iCloudItemDidChanged:self URL:url];
}

@end
