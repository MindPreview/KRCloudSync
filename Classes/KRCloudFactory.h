//
//  KRCloudFactory.h
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRCloudService.h"
#import "KRFileService.h"
#import "KRConflictResolver.h"
#import "KRResourceFilter.h"

@interface KRCloudFactory : NSObject

@property (nonatomic) KRCloudService* cloudService;
@property (nonatomic) KRFileService* fileService;
@property (nonatomic) KRResourceFilter* filter;
@property (nonatomic) KRConflictResolver* conflictResolver;
@property (nonatomic) NSDate* lastSyncTime;
@property (nonatomic) BOOL shouldSyncWithRemote;

@end
