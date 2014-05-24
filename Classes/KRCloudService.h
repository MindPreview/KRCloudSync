//
//  KRCloudService.h
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRCloudSyncBlocks.h"

@class KRResourceProperty;

@protocol KRCloudServiceDelegate;

@interface KRCloudService : NSObject

@property (nonatomic, weak) id<KRCloudServiceDelegate> delegate;
@property (nonatomic) NSString* localDocumentsPath;
@property (nonatomic) NSString* remoteDocumentsPath;
@property (nonatomic) NSArray* filters;

-(id)initWithDocumentsPaths:(NSString*)documentsPath remote:(NSString*)remoteDocumentsPath;

-(BOOL)loadResourcesUsingBlock:(KRResourcesCompletedBlock)completed;

-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRCloudSyncCompletedBlock)completed;

-(void)renameFileUsingBlock:(NSString*)filePath
				newFileName:(NSString*)newFileName
			 completedBlock:(KRCloudSyncResultBlock)block;

-(BOOL)addFileUsingBlock:(NSString*)filePath
		  completedBlock:(KRCloudSyncResultBlock)block;
-(BOOL)addFile:(NSString*)filePath error:(NSError**)error;

-(BOOL)removeFileUsingBlock:(NSString*)fileName
			 completedBlock:(KRCloudSyncResultBlock)block;

-(void)enableUpdate;
-(void)disableUpdate;

-(KRResourceProperty*)createResourceFromLocalResource:(KRResourceProperty*)resource;

@end


@protocol KRCloudServiceDelegate <NSObject>
@optional
-(void)itemDidChanged:(KRCloudService*)service URL:(NSURL*)url;

@end