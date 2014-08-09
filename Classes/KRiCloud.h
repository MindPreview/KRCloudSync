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

@interface KRiCloud : NSObject<NSFilePresenter>{
	NSURL* _presentedItemURL;
	NSMetadataQuery* _query;
	NSOperationQueue* _presentedItemOperationQueue;
}

@property (nonatomic, weak) id<KRiCloudDelegate> delegate;

+(KRiCloud*)sharedInstance;

-(BOOL)loadFilesWithPredicate:(NSPredicate*)predicate
			   completedBlock:(KRiCloudCompletedBlock)block;

-(void)startDownloadUsingBlock:(NSMetadataQuery*)query
				 progressBlock:(KRiCloudProgressBlock)block;
-(void)startDownloadWithURLsUsingBlock:(NSArray*)URLs
						 progressBlock:(KRiCloudProgressBlock)block;

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

-(void)enableUpdate;
-(void)disableUpdate;

@end

@protocol KRiCloudDelegate <NSObject>
- (void)iCloudItemDidChanged:(KRiCloud*)iCloud URL:(NSURL*)url;
@end
