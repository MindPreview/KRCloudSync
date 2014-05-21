//
//  KRiCloud.h
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^KRiCloudCompletedBlock)(NSMetadataQuery*, NSError*);
typedef void (^KRiCloudSaveFileCompletedBlock)(id, NSError*);
typedef void (^KRiCloudRemoveFileCompletedBlock)(BOOL, NSError*);
typedef void (^KRiCloudBatchSyncCompeletedBlock)
				(NSArray* toLocalURLs, NSArray* toLocalURLErrors,
					NSArray* fromLocalURLs, NSArray* fromLocalURLErrors);

typedef void (^KRiCloudResultBlock)(BOOL succeeded, NSError* error);
typedef void (^KRiCloudDownloadResultBlock)(BOOL succeeded, NSUInteger count, NSError* error);
typedef void (^KRiCloudProgressBlock)(NSURL* url, double progress);

@protocol KRiCloudDelegate;

@interface KRiCloudContext : NSObject
@property (nonatomic) id key;
@property (nonatomic) NSMetadataQuery* query;
@property (nonatomic, copy) KRiCloudCompletedBlock block;
@end

@interface KRiCloud : NSObject<NSFilePresenter>{
	NSURL* _presentedItemURL;
	NSMetadataQuery* _query;
	NSMutableDictionary* _queryContexts;
	NSOperationQueue* _presentedItemOperationQueue;
	KRiCloudProgressBlock _progressBlock;
	BOOL _shouldUpdateQuery;
}

@property (nonatomic, weak) id<KRiCloudDelegate> delegate;

+(KRiCloud*)sharedInstance;

-(BOOL)loadFilesWithPredicate:(NSPredicate*)predicate
			   completedBlock:(KRiCloudCompletedBlock)block;

-(void)startDownloadUsingBlock:(NSMetadataQuery*)query
				 progressBlock:(KRiCloudProgressBlock)block;
-(void)startDownloadWithURLsUsingBlock:(NSArray*)URLs
						 progressBlock:(KRiCloudProgressBlock)block;

-(BOOL)monitorFilesWithPredicate:(NSPredicate*)predicate
				  completedBlock:(KRiCloudCompletedBlock)block;

-(BOOL)saveToUbiquityContainer:(id)key
						   url:(NSURL*)url
				destinationURL:(NSURL*)destinationURL
				completedBlock:(KRiCloudSaveFileCompletedBlock)block;

-(BOOL)saveToUbiquityContainerWithFileCoordinator:(NSFileCoordinator*)fileCoordinator
											  url:(NSURL*)url
								   destinationURL:(NSURL*)destinationURL
											error:(NSError**)error;

-(BOOL)saveToDocument:(id)key
				  url:(NSURL*)url
	   destinationURL:(NSURL*)destinationURL
	   completedBlock:(KRiCloudSaveFileCompletedBlock)block;

-(BOOL)saveToDocumentWithFileCoordinator:(NSFileCoordinator*)fileCoordinator
									 url:(NSURL*)url
						  destinationURL:(NSURL*)destinationURL
								   error:(NSError**)error;


-(void)renameFileUsingBlock:(NSURL*)fileURL
					newName:(NSString*)newFileName
					  block:(KRiCloudResultBlock)block;

-(BOOL)renameFile:(NSURL*)sourceURL
		   newURL:(NSURL*)destinationURL
			error:(NSError**)error;

-(BOOL)removeFile:(NSString*)fileName completedBlock:(KRiCloudRemoveFileCompletedBlock)block;
-(BOOL)removeAllFiles:(KRiCloudRemoveFileCompletedBlock)block;

-(BOOL)batchLockAndSync:(NSArray*)readingURLs toLocalURLs:(NSArray*)toLocalURLs
			writingURLs:(NSArray*)writingURLs fromLocalURLs:(NSArray*)fromLocalURLs
				  error:(NSError**)outError
		 completedBlock:(KRiCloudBatchSyncCompeletedBlock)block;

-(void)enableUpdate;
-(void)disableUpdate;

@end

@protocol KRiCloudDelegate <NSObject>
- (void)iCloudItemDidChanged:(KRiCloud*)iCloud URL:(NSURL*)url;
@end
