//
//  KRCloudSync.h
//  CloudSync
//
//  Created by allting on 12. 10. 10..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRCloudPreferences.h"
#import "KRCloudFactory.h"
#import "KRCloudSyncBlocks.h"

typedef enum {
	kKRiCloudService,
	kKRDropboxService
}KRServiceType;

@interface KRCloudSync : NSObject

@property (nonatomic) KRCloudPreferences* preferences;
@property (nonatomic) KRCloudFactory* factory;

+(BOOL)isAvailableService:(KRServiceType)serviceType block:(KRServiceAvailableBlock)block;

+(BOOL)isAvailableiCloudUsingBlock:(KRServiceAvailableBlock)availableBlock;
+(BOOL)removeAlliCloudFileUsingBlock:(KRiCloudRemoveFileBlock)block;

-(id)initWithFactory:(KRCloudFactory*)factory;

-(KRCloudService*)service;

-(BOOL)sync;
-(BOOL)syncUsingBlock:(KRCloudSyncCompletedBlock)completed;
-(BOOL)syncUsingBlocks:(KRCloudSyncStartBlock)startBlock
		 progressBlock:(KRCloudSyncProgressBlock)progresBlock
		completedBlock:(KRCloudSyncCompletedBlock)completedBlock;


@end
