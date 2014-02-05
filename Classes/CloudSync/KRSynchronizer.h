//
//  KRSynchronizer.h
//  CloudSync
//
//  Created by allting on 12. 10. 14..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRCloudFactory.h"
#import "KRCloudService.h"
#import "KRCloudSyncBlocks.h"

@interface KRSynchronizer : NSObject

@property (nonatomic) KRCloudService* cloudService;

-(id)initWithFactory:(KRCloudFactory*)factory;

-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRSynchronizerCompletedBlock)completed;

@end
