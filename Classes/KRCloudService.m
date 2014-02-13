//
//  KRCloudService.m
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRCloudService.h"

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

-(void)renameFileUsingBlock:(NSString*)fileName
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

@end
