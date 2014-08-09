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

@interface KRiCloud()
@property (nonatomic, copy) KRiCloudProgressBlock progressBlock;
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
		
		_presentedItemOperationQueue = [[NSOperationQueue alloc] init];
		[_presentedItemOperationQueue setName:[NSString stringWithFormat:@"presenter queue -- %@", self]];
		[_presentedItemOperationQueue setMaxConcurrentOperationCount:1];
        
		[NSFileCoordinator addFilePresenter:self];
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
	_presentedItemOperationQueue = nil;
}

#pragma mark - loadFiles
-(BOOL)loadFilesWithPredicate:(NSPredicate*)predicate completedBlock:(KRiCloudCompletedBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
    
    [_query setPredicate:predicate];
    // fetch the percent-downloaded key when updating results
    [_query setValueListAttributes:@[NSMetadataUbiquitousItemPercentDownloadedKey,
                                        NSMetadataUbiquitousItemDownloadingStatusKey]];
	
	__block id notificationId = nil;
	typedef void (^notificationObserverBlock)(NSNotification *);
	notificationObserverBlock notificationBlock = ^(NSNotification* notification){
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
												  usingBlock:notificationBlock];
    
    NSAssert([NSThread isMainThread], @"Must be main thread");
	[_query startQuery];
    [_query enableUpdates];
	
	return YES;
}

-(void)startDownloadUsingBlock:(NSMetadataQuery*)query
				 progressBlock:(KRiCloudProgressBlock)block{
	_progressBlock = block;

	NSFileManager* fileManager = [NSFileManager defaultManager];
	for(NSMetadataItem* item in [query results]) {
		NSString* status  = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
		if([status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]){
            NSURL* url = [item valueForAttribute:NSMetadataItemURLKey];
            NSError* error = nil;
            if([fileManager startDownloadingUbiquitousItemAtURL:url error:&error]){
                if(block){
                    block(url, 0.f);
                }
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
			
            NSString* status  = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
            if(![status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent]){
                NSError* error = nil;
                if([fileManager startDownloadingUbiquitousItemAtURL:url error:&error]){
                    if(block){
                        block(url, 0.f);
                    }
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
        NSString* status  = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
        
        if([status isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]){
            NSLog(@"queryDidUpdateNotification - url:%@, status:%@", url, NSMetadataUbiquitousItemDownloadingStatusNotDownloaded);
            NSFileManager* fileManager = [NSFileManager defaultManager];
            NSError* error = nil;
            if([fileManager startDownloadingUbiquitousItemAtURL:url error:&error]){
                NSLog(@"Start Download - url:%@", url);
            }
        }
	}

	[query enableUpdates];
}

-(void)queryDidProgressNotification:(NSNotification*)notification{
//	NSMetadataQuery* query = [notification object];
//	NSLog(@"queryDidProgressNotification - newQuery:%@, count:%d", query, [query resultCount]);
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
    [fileCoordinator coordinateReadingItemAtURL:url
										options:NSFileCoordinatorReadingWithoutChanges
										  error:&outError
									 byAccessor:^(NSURL *updatedURL) {
										 [self copyFile:updatedURL toURL:destinationURL error:&innerError];
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
-(void)renameFileUsingBlock:(NSURL*)fileURL
					newName:(NSString*)newFileName
					  block:(KRiCloudResultBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return;
	
    NSString* fileName = [[fileURL path] lastPathComponent];
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
	
	NSLog(@"NSFilePresenter-presentedItemURL:%@", _presentedItemURL);
	return _presentedItemURL;
}

- (NSOperationQueue *)presentedItemOperationQueue{
	NSLog(@"NSFilePresenter-presentedItemOperationQueue");
    return _presentedItemOperationQueue;
}

- (void)relinquishPresentedItemToReader:(void (^)(void (^reacquirer)(void))) reader{
	NSLog(@"NSFilePresenter-relinquishPresentedItemToReader");
	[_query disableUpdates];
	
	reader(^{
		NSLog(@"NSFilePresenter-relinquishPresentedItemToReader - enable");
		[_query enableUpdates];
	});
}
- (void)relinquishPresentedItemToWriter:(void (^)(void (^reacquirer)(void)))writer;{
	NSLog(@"NSFilePresenter-relinquishPresentedItemToWriter");
	[_query disableUpdates];
	
	writer(^{
		NSLog(@"NSFilePresenter-relinquishPresentedItemToWriter - enable");
		[_query enableUpdates];
	});
}

- (void)savePresentedItemChangesWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler{
    NSLog(@"NSFilePresenter-savePresentedItemChangesWithCompletionHandler");
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler{
    NSLog(@"NSFilePresenter-accommodatePresentedItemDeletionWithCompletionHandler");
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL;{
    NSLog(@"NSFilePresenter-presentedItemDidMoveToURL: %@", newURL);
	_presentedItemURL = newURL;
}

// This gets called for local coordinated writes and for unsolicited incoming edits from iCloud. From the header, "Your NSFileProvider may be sent this message without being sent -relinquishPresentedItemToWriter: first. Make your application do the best it can in that case."
- (void)presentedItemDidChange;{
    NSLog(@"NSFilePresenter-presentedItemDidChange");
}

- (void)presentedItemDidGainVersion:(NSFileVersion *)version;{
    NSLog(@"NSFilePresenter-presentedItemDidGainVersion");
}

- (void)presentedItemDidLoseVersion:(NSFileVersion *)version;{
    NSLog(@"NSFilePresenter-presentedItemDidLoseVersion");
}

- (void)presentedItemDidResolveConflictVersion:(NSFileVersion *)version;{
    NSLog(@"NSFilePresenter-presentedItemDidResolveConflictVersion");
}

- (void)presentedSubitemAtURL:(NSURL *)url didGainVersion:(NSFileVersion *)version{
	NSLog(@"NSFilePresenter-presentedSubitemAtURL-url:%@, didGainVersion:%@", url, version);
}

- (void)presentedSubitemAtURL:(NSURL *)url didLoseVersion:(NSFileVersion *)version{
	NSLog(@"NSFilePresenter-presentedSubitemAtURL-url:%@, didLoseVersion:%@", url, version);
}

- (void)presentedSubitemAtURL:(NSURL *)url didResolveConflictVersion:(NSFileVersion *)version{
	NSLog(@"NSFilePresenter-presentedSubitemAtURL-url:%@, didResolveConflictVersion:%@", url, version);
}

- (void)accommodatePresentedSubitemDeletionAtURL:(NSURL *)url completionHandler:(void (^)(NSError *errorOrNil))completionHandler{
	NSLog(@"NSFilePresenter-accommodatePresentedSubitemDeletionAtURL-url:%@", url);
	completionHandler(nil);
}

- (void)presentedSubitemDidAppearAtURL:(NSURL *)url{
	NSLog(@"NSFilePresenter-presentedSubitemDidAppearAtURL:%@", url);
}

- (void)presentedSubitemAtURL:(NSURL *)oldURL didMoveToURL:(NSURL *)newURL{
	NSLog(@"NSFilePresenter-presentedSubitemAtURL - oldURL:%@, didMoveToURL:%@", oldURL, newURL);
}

- (void)presentedSubitemDidChangeAtURL:(NSURL *)url{
	NSLog(@"NSFilePresenter-presentedSubitemDidChangeAtURL:%@", url);
	// remove a file that has named of url, then sync again.
	
	if([_delegate respondsToSelector:@selector(iCloudItemDidChanged:URL:)])
		[_delegate iCloudItemDidChanged:self URL:url];
}

@end
