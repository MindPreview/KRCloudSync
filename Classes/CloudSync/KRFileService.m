//
//  KRFileService.m
//  CloudSync
//
//  Created by allting on 12. 10. 13..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRFileService.h"
#import "KRResourceProperty.h"
#import "KRResourceFilter.h"

@implementation KRFileService

-(id)initWithDocumentsPaths:(NSString*)path remote:(NSString*)remotePath filter:(KRResourceFilter*)filter{
    self = [super init];
	if(self){
		self.localDocumentsPath = path;
		self.remoteDocumentsPath = remotePath;
		self.filter = filter;
	}
	return self;
}

-(NSString*)documentsPath{
	if(0==[_localDocumentsPath length])
		return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	return _localDocumentsPath;
}

-(NSArray*)load{
	return nil;
}

-(KRResourceProperty*)createLocalResourceFromRemoteResource:(KRResourceProperty*)remoteResource{
	NSString* documentPath = self.documentsPath;
    
    // 하위 디렉토리가 포함되도록 하기 위해,
    // 리모트의 절대 패스를 로컬의 상대 패스로 사용함.
    NSString* filePath = [remoteResource pathByDeletingSubPath:self.remoteDocumentsPath];
    filePath = [filePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* localPath = [documentPath stringByAppendingPathComponent:filePath];
    
    return [[KRResourceProperty alloc] initWithProperties:[NSURL fileURLWithPath:localPath]
                                              createdDate:[remoteResource createdDate]
                                             modifiedDate:[remoteResource modifiedDate]
                                                     size:[remoteResource size]];
}
@end
