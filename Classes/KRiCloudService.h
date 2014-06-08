//
//  KRiCloudService.h
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRCloudService.h"
#import "KRCloudSyncBlocks.h"
#import "KRResourceFilter.h"
#import "KRiCloud.h"

typedef void (^KRiCloudServiceLoadingResultBlock)(NSMetadataQuery* query, NSError* error);
typedef void (^KRiCloudServiceProgressBlock)(NSURL* url, double progress);
typedef void (^KRiCloudServiceDownloadResultBlock)(BOOL succeeded, NSUInteger count, NSError* error);

@interface KRiCloudService : KRCloudService<KRiCloudDelegate>{
	KRiCloud* _iCloud;
}

@property (nonatomic) NSString* documentPath;
@property (nonatomic) KRResourceFilter* filter;

+(BOOL)isAvailableUsingBlock:(KRServiceAvailableBlock)availableBlock;
+(BOOL)removeAllFilesUsingBlock:(KRiCloudResultBlock)block;
+(BOOL)downloadFilesWithFilterUsingBlock:(NSString*)path
							   predicate:(NSPredicate*)predicate
						  loadCountBlock:(KRiCloudDownloadResultBlock)loadCountBlock
						   progressBlock:(KRiCloudProgressBlock)progressBlock
						  completedBlock:(KRiCloudDownloadResultBlock)completedBlock;

-(id)initWithDocumentsPath:(NSString*)path filter:(KRResourceFilter*)filter;

-(BOOL)loadResourcesUsingBlock:(KRResourcesCompletedBlock)completed;
-(BOOL)loadResourcesWithPredicateUsingBlock:(NSPredicate*)predicate
									  block:(KRiCloudServiceLoadingResultBlock)completed;
-(void)downloadURLUsingBlock:(NSArray*)urls
						path:(NSString*)path
			   progressBlock:(KRiCloudServiceProgressBlock)progressBlock
			  completedBlock:(KRiCloudServiceDownloadResultBlock)completedBlock;

-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRCloudSyncCompletedBlock)completed;

-(BOOL)addFileUsingBlock:(NSString*)filePath
		  completedBlock:(KRCloudSyncResultBlock)block;
-(BOOL)addFile:(NSString*)filePath error:(NSError**)error;

-(BOOL)removeFileUsingBlock:(NSString*)fileName
			 completedBlock:(KRCloudSyncResultBlock)block;


@end
