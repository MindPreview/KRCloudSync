//
//  KRDropboxService.h
//  CloudSync
//
//  Created by allting on 1/29/14.
//  Copyright (c) 2014 allting. All rights reserved.
//

#import "KRCloudService.h"
#import "KRResourceFilter.h"

@interface KRDropboxService : KRCloudService

+(BOOL)isAvailableUsingBlock:(KRServiceAvailableBlock)availableBlock;

-(id)initWithDocumentsPaths:(NSString*)path remote:(NSString *)remotePath filter:(KRResourceFilter*)filter;

@end
