//
//  iCloudServiceMock.h
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRCloudService.h"

@interface MockiCloudService : KRCloudService

@property (nonatomic, readonly) NSArray* resources;

@end
