//
//  KRFileService.h
//  CloudSync
//
//  Created by allting on 12. 10. 13..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KRResourceProperty;
@class KRResourceFilter;

@interface KRFileService : NSObject

@property (nonatomic) NSString* localDocumentsPath;
@property (nonatomic) NSString* remoteDocumentsPath;
@property (nonatomic) KRResourceFilter* filter;

-(id)initWithDocumentsPaths:(NSString*)path remote:(NSString*)remotePath filter:(KRResourceFilter*)filter;

-(NSArray*)load;

-(KRResourceProperty*)createLocalResourceFromRemoteResource:(KRResourceProperty*)remoteResource;

@end
