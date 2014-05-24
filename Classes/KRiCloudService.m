//
//  KRiCloudService.m
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRiCloudService.h"
#import "KRiCloud.h"
#import "KRResourceProperty.h"
#import "KRSyncItem.h"
#import "KRLocalFileService.h"

@implementation KRiCloudService

+(BOOL)isAvailableUsingBlock:(KRServiceAvailableBlock)availableBlock{
	NSAssert(availableBlock, @"Mustn't be nil");
	if(!availableBlock)
		return NO;
	
	dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSURL *ubiquityContainer = [fileManager URLForUbiquityContainerIdentifier:nil];
		
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		dispatch_async(mainQueue, ^{
			if(ubiquityContainer)
				availableBlock(YES);
			else
				availableBlock(NO);
		});
	});
	return YES;
}

+(BOOL)removeAllFilesUsingBlock:(KRiCloudResultBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
	
	KRiCloud* cloud = [[KRiCloud alloc] init];
	[cloud removeAllFiles:^(BOOL succeeded, NSError* error){
		block(succeeded, error);
	}];
	
	return YES;
}

+(BOOL)downloadFilesWithFilterUsingBlock:(NSString*)path
							   predicate:(NSPredicate*)predicate
						  loadCountBlock:(KRiCloudDownloadResultBlock)loadCountBlock
						   progressBlock:(KRiCloudProgressBlock)progressBlock
						  completedBlock:(KRiCloudDownloadResultBlock)completedBlock{
	NSAssert(completedBlock, @"Mustn't be nil");
	if(!completedBlock)
		return NO;

	KRiCloud* cloud = [[KRiCloud alloc] init];
	[cloud loadFilesWithPredicate:predicate
				   completedBlock:^(NSMetadataQuery* query, NSError* error){
					   if([error code]){
						   completedBlock(NO, 0, error);
						   return;
					   }
					   
					   if(loadCountBlock){
						   loadCountBlock(YES, [query resultCount], error);
					   }
					   
					   if([query resultCount]==0){
						   completedBlock(YES, 0, error);
						   return;
					   }
					   
					   [cloud startDownloadUsingBlock:query progressBlock:progressBlock];
					   [KRiCloudService waitDownloadAndCopyUsingBlock:cloud
																query:query
																 path:path
																block:completedBlock];
				  }];
	return YES;
}

+(void)waitDownloadAndCopyUsingBlock:(KRiCloud*)cloud
							   query:(NSMetadataQuery*)query
								path:(NSString*)path
							   block:(KRiCloudDownloadResultBlock)block{
	NSMutableArray* urls = [NSMutableArray arrayWithCapacity:[query resultCount]];
	for(NSMetadataItem* item in [query results]){
		NSURL* url = [item valueForAttribute:NSMetadataItemURLKey];
		[urls addObject:url];
	}
	
	[KRiCloudService waitDownloadAndCopyWithURLsUsingBlock:cloud urls:urls path:path block:block];
}

+(void)waitDownloadAndCopyWithURLsUsingBlock:(KRiCloud*)cloud
										urls:(NSArray*)urls
										path:(NSString*)path
									   block:(KRiCloudDownloadResultBlock)block{
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		NSUInteger downloadedCount=0;
		NSError* error = nil;
		NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc]initWithFilePresenter:cloud];
		for(NSURL* url in urls){
			NSString* fileName = [url lastPathComponent];
			
			NSString* newPath = [KRFileService uniqueFilePathInDirectory:path fileName:fileName];
			NSURL* localURL = [NSURL fileURLWithPath:newPath];
			
			[cloud saveToDocumentWithFileCoordinator:fileCoordinator
												 url:url
									  destinationURL:localURL
											   error:&error];
			if(0==[error code])
				downloadedCount++;
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			block(YES, downloadedCount, error);
		});
	});
}

-(id)init{
	self = [super init];
	if(self){
		_iCloud = [[KRiCloud alloc]init];
		_iCloud.delegate = self;
	}
	return self;
}

-(id)initWithDocumentsPath:(NSString*)path filter:(KRResourceFilter*)filter{
	self = [super initWithDocumentsPaths:path remote:@"/"];
	if(self){
		self.filter = filter;
		_iCloud = [[KRiCloud alloc]init];
		_iCloud.delegate = self;
	}
	return self;
}

-(NSString*)documentPath{
	if(0==[_documentPath length])
		return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	return _documentPath;
}

-(BOOL)loadResourcesUsingBlock:(KRResourcesCompletedBlock)completed{
	NSAssert(completed, @"Mustn't be nil");
	if(!completed)
		return NO;
	
	NSPredicate *predicate = [self.filter createPredicate];
	[_iCloud loadFilesWithPredicate:predicate
					 completedBlock:^(NSMetadataQuery* query, NSError* error){
						 NSMutableArray* resources  = [NSMutableArray arrayWithCapacity:[query resultCount]];
						 for(NSMetadataItem *item in [query results]){
							 KRResourceProperty* resource = [[KRResourceProperty alloc]initWithMetadataItem:item];
							 [resources addObject:resource];
						 }
						 
						 completed(resources, nil);
					 }];
	
	return YES;

}

-(BOOL)loadResourcesWithPredicateUsingBlock:(NSPredicate*)predicate
									  block:(KRiCloudServiceLoadingResultBlock)completed{
	NSAssert(completed, @"Mustn't be nil");
	if(!completed)
		return NO;
	
	return [_iCloud loadFilesWithPredicate:predicate completedBlock:completed];
}

-(void)downloadURLUsingBlock:(NSArray*)urls
						path:(NSString*)path
			   progressBlock:(KRiCloudServiceProgressBlock)progressBlock
			  completedBlock:(KRiCloudServiceDownloadResultBlock)completedBlock{
	[_iCloud startDownloadWithURLsUsingBlock:urls progressBlock:progressBlock];
	[KRiCloudService waitDownloadAndCopyWithURLsUsingBlock:_iCloud
													  urls:urls
													  path:path
													 block:completedBlock];
}

-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRCloudSyncCompletedBlock)completed{
	NSAssert(completed, @"Mustn't be nil");
	if(!completed)
		return NO;
	
	[self startDownloadAndProcessProgressUsingBlock:syncItems block:progressBlock];
	
	dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
		NSError* error = nil;
		
		NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc]initWithFilePresenter:_iCloud];
		for(KRSyncItem* item in syncItems){
			if(KRSyncItemActionNone == item.action)
				continue;
			
			NSError* error = nil;

			if(KRSyncItemActionRemoteAccept == item.action){
				if(0 == item.localResource.size.unsignedIntegerValue)
					continue;
				
				[self saveToCloudWithFileCoordinator:fileCoordinator syncItem:item error:&error];
				item.error = error;
			}else{
				if(0 == item.remoteResource.size.unsignedIntegerValue)
					continue;
				
				[self saveToLocalWithFileCoordinator:fileCoordinator syncItem:item error:&error];
				item.error = error;
			}
		}
		
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		dispatch_async(mainQueue, ^{
			completed(syncItems, error);
		});
	});

	return YES;
}

-(void)startDownloadAndProcessProgressUsingBlock:(NSArray*)syncItems
										   block:(KRCloudSyncProgressBlock)block{
	NSMutableArray* urls = [NSMutableArray arrayWithCapacity:[syncItems count]];
	for(KRSyncItem* item in syncItems){
		if(item.remoteResource.URL)
			[urls addObject:item.remoteResource.URL];
	}
	
	[_iCloud startDownloadWithURLsUsingBlock:urls progressBlock:^(NSURL *url, double progress) {
		if(!block)
			return;

		[self raiseSyncItemProgress:syncItems
				 currentSyncItemUrl:url
						   progress:progress
							  block:block];
	}];
}

-(void)raiseSyncItemProgress:(NSArray*)syncItems
		  currentSyncItemUrl:(NSURL*)url
					progress:(float)progress
					   block:(KRCloudSyncProgressBlock)block{
	for(KRSyncItem* item in syncItems){
		if(![url isEqual:item.remoteResource.URL])
			continue;
		
		if(progress<100.f)
			block(item, progress);
		else{
			[self saveSyncItemToLocalUsingBlock:item block:^(BOOL succeeded, NSError* error){
				block(item, progress);
			}];
		}
	}
}

-(void)saveSyncItemToLocalUsingBlock:(KRSyncItem*)item block:(KRiCloudResultBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		NSError* error = nil;
		
		NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc]initWithFilePresenter:_iCloud];
		BOOL ret = [self saveToLocalWithFileCoordinator:fileCoordinator syncItem:item error:&error];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			block(ret, error);
		});
	});

}

-(BOOL)saveToCloudWithFileCoordinator:(NSFileCoordinator*)fileCoordinator
							 syncItem:(KRSyncItem*)item
								error:(NSError**)outError{
	NSURL* remoteURL = item.remoteResource.URL;
	if(!remoteURL)
		remoteURL = [self createRemoteURL:item.localResource.URL];
	NSURL* localURL = item.localResource.URL;
	
	return [_iCloud saveToUbiquityContainerWithFileCoordinator:fileCoordinator
														   url:localURL
												destinationURL:remoteURL
														 error:outError];
}

-(BOOL)saveToLocalWithFileCoordinator:(NSFileCoordinator*)fileCoordinator
							 syncItem:(KRSyncItem*)item
								error:(NSError**)outError{
	NSURL* localURL = item.localResource.URL;
	if(!localURL)
		localURL = [self createLocalURL:item.remoteResource.URL];
	NSURL* remoteURL = item.remoteResource.URL;
	
	return [_iCloud saveToDocumentWithFileCoordinator:fileCoordinator
												  url:remoteURL
									   destinationURL:localURL
												error:outError];
}


-(BOOL)batchSyncUsingBlock:(NSArray*)syncItems
	   completedBlock:(KRCloudSyncCompletedBlock)completed{
	NSAssert(completed, @"Mustn't be nil");
	if(!completed)
		return NO;
	
	dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
		
		NSUInteger count = [syncItems count];
		
		NSMutableDictionary* binder = [NSMutableDictionary dictionaryWithCapacity:count];
		
		NSMutableArray* readingURLs = [NSMutableArray arrayWithCapacity:count];
		NSMutableArray* toLocalURLs = [NSMutableArray arrayWithCapacity:count];
		NSMutableArray* writingURLs = [NSMutableArray arrayWithCapacity:count];
		NSMutableArray* fromLocalURLs = [NSMutableArray arrayWithCapacity:count];
		
		for(KRSyncItem* item in syncItems){
			if(KRSyncItemActionNone == item.action)
				continue;
			else if(KRSyncItemActionRemoteAccept == item.action){
				NSURL* remoteURL = item.remoteResource.URL;
				if(!remoteURL)
					remoteURL = [self createRemoteURL:item.localResource.URL];
				
				[writingURLs addObject:remoteURL];
				[fromLocalURLs addObject:item.localResource.URL];
				
				[binder setObject:item forKey:item.localResource.URL];
			}else{
				NSURL* localURL = item.localResource.URL;
				if(!localURL)
					localURL = [self createLocalURL:item.remoteResource.URL];
				
				[readingURLs addObject:item.remoteResource.URL];
				[toLocalURLs addObject:localURL];
				
				[binder setObject:item forKey:item.remoteResource.URL];
			}
		}
		
		NSError* error = nil;
		KRiCloud* iCloud = [[KRiCloud alloc]init];

		[iCloud batchLockAndSync:readingURLs
					 toLocalURLs:toLocalURLs
					 writingURLs:writingURLs
				   fromLocalURLs:fromLocalURLs
						   error:&error
				  completedBlock:^(NSArray *toLocalURLs, NSArray *toLocalURLErrors,
								 NSArray *fromLocalURLs, NSArray *fromLocalURLErrors) {
					NSUInteger count=[toLocalURLs count];
					for(NSUInteger i=0; i<count; i++){
						NSURL* url = [toLocalURLs objectAtIndex:i];
						KRSyncItem* item = [binder objectForKey:url];
						if([toLocalURLErrors objectAtIndex:i] != [NSNull null])
							item.error = [toLocalURLErrors objectAtIndex:i];
					}
					count = [fromLocalURLs count];
					for(NSUInteger i=0; i<count; i++){
						NSURL* url = [fromLocalURLs objectAtIndex:i];
						KRSyncItem* item = [binder objectForKey:url];
						if([fromLocalURLErrors objectAtIndex:i] != [NSNull null])
							item.error = [fromLocalURLErrors objectAtIndex:i];
					}
				}];
		
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		dispatch_async(mainQueue, ^{
			completed(syncItems, error);
		});
	});
	return YES;
}

-(void)renameFileUsingBlock:(NSString*)filePath
				newFileName:(NSString*)newFileName
			 completedBlock:(KRCloudSyncResultBlock)block{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return;
	
    NSURL* fileURL = [NSURL URLWithString:filePath];
	[_iCloud renameFileUsingBlock:fileURL newName:newFileName block:^(BOOL ret, NSError* error){
		block(ret, error);
	}];
    
	return;
}

-(BOOL)addFileUsingBlock:(NSString*)filePath
		  completedBlock:(KRCloudSyncResultBlock)block
{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		NSError* error = nil;
		BOOL succeeded = [self addFile:filePath error:&error];
		dispatch_async(dispatch_get_main_queue(), ^{
			block(succeeded, error);
		});
	});
	
	return YES;
}

-(BOOL)addFile:(NSString*)filePath error:(NSError**)outError{
	// should create new KRiCloud instance.
	KRiCloud* cloud = [[KRiCloud alloc]init];
	NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc]initWithFilePresenter:cloud];
	
	NSURL* localURL = [NSURL fileURLWithPath:filePath];
	NSURL* destinationURL = [self createRemoteURL:localURL];
	
	BOOL succeeded = [cloud saveToUbiquityContainerWithFileCoordinator:fileCoordinator
																   url:localURL
														destinationURL:destinationURL
																 error:outError];
	return succeeded;
}

-(BOOL)removeFileUsingBlock:(NSString*)fileName
			 completedBlock:(KRCloudSyncResultBlock)block
{
	NSAssert(block, @"Mustn't be nil");
	if(!block)
		return NO;
	
	// should create new KRiCloud instance.
	KRiCloud* cloud = [[KRiCloud alloc]init];
	[cloud removeFile:fileName completedBlock:^(BOOL succeeded, NSError* error){
		block(succeeded, error);
	}];
	
	return YES;
}

-(NSURL*)createRemoteURL:(NSURL*)localURL{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *ubiquityContainer = [fileManager URLForUbiquityContainerIdentifier:nil];

	NSString* filePath = [NSString stringWithFormat:@"Documents/%@", [localURL lastPathComponent]];
	return [ubiquityContainer URLByAppendingPathComponent:filePath];
}

-(NSURL*)createLocalURL:(NSURL*)url{
	NSString* fileName = [url lastPathComponent];
	NSString* documentPath = self.documentPath;
	NSString* path = [documentPath stringByAppendingPathComponent:fileName];
	return [NSURL fileURLWithPath:path];
}

-(void)enableUpdate{
	[_iCloud enableUpdate];
}

-(void)disableUpdate{
	[_iCloud disableUpdate];
}


#pragma mark - KRiCloud delegate
-(void)iCloudItemDidChanged:(KRiCloud *)iCloud URL:(NSURL *)url{
	if([self.delegate respondsToSelector:@selector(itemDidChanged:URL:)])
		[self.delegate itemDidChanged:self URL:url];
}

@end
