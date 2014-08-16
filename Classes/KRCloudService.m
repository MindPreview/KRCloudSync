//
//  KRCloudService.m
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRCloudService.h"
#import "KRResourceProperty.h"

@implementation KRCloudService

-(id)initWithDocumentsPaths:(NSString*)documentsPath remote:(NSString*)remoteDocumentsPath{
    self = [super init];
    if(self){
        self.localDocumentsPath = documentsPath;
        self.remoteDocumentsPath = remoteDocumentsPath;
    }
    return self;
}

-(BOOL)loadResourcesUsingBlock:(KRResourcesCompletedBlock)completed{
    if(completed)
        completed(nil, nil);
    
	return NO;
}

-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRCloudSyncCompletedBlock)completed{
	NSAssert(completed, @"Mustn't be nil");
	if(!completed)
		return NO;
	
	completed(syncItems, nil);
	return YES;
}

-(void)renameFileUsingBlock:(NSString*)filePath
				newFileName:(NSString*)newFileName
			 completedBlock:(KRCloudSyncResultBlock)block{
}

-(BOOL)addFileUsingBlock:(NSString*)filePath
		  completedBlock:(KRCloudSyncResultBlock)block{
	return NO;
}
-(BOOL)addFile:(NSString*)filePath error:(NSError**)outError{
	return NO;
}

-(BOOL)removeFileUsingBlock:(NSString*)fileName
			 completedBlock:(KRCloudSyncResultBlock)block{
	return NO;
}

-(void)enableUpdate{
    
}

-(void)disableUpdate{
    
}

-(KRResourceProperty*)createResourceFromLocalResource:(KRResourceProperty*)resource{
    NSString* filePath = [resource pathByDeletingSubPath:self.localDocumentsPath];
    filePath = [filePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* path = [self.remoteDocumentsPath stringByAppendingPathComponent:filePath];
    
    return [[KRResourceProperty alloc] initWithProperties:[NSURL fileURLWithPath:path]
                                              createdDate:[resource createdDate]
                                             modifiedDate:[resource modifiedDate]
                                                     size:[resource size]];
}

-(void)publishingURLUsingBlock:(NSString*)localPath block:(KRCloudSyncPublishingURLBlock)block{
}

@end
