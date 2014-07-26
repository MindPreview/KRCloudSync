//
//  KRCloudSync.m
//  CloudSync
//
//  Created by allting on 12. 10. 10..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRCloudSync.h"
#import "KRResourceLoader.h"
#import "KRResourceProperty.h"
#import "KRResourceComparer.h"
#import "KRSynchronizer.h"
#import "KRiCloudFactory.h"
#import "KRiCloudService.h"
#import "KRDropboxService.h"

@implementation KRCloudSync

+(BOOL)isAvailableService:(KRServiceType)serviceType block:(KRServiceAvailableBlock)block{
    if(kKRiCloudService == serviceType)
        return [KRiCloudService isAvailableUsingBlock:block];
    
    return [KRDropboxService isAvailableUsingBlock:block];
}

+(BOOL)isAvailableiCloudUsingBlock:(KRServiceAvailableBlock)availableBlock{
	return [KRiCloudService isAvailableUsingBlock:availableBlock];
}

+(BOOL)removeAlliCloudFileUsingBlock:(KRiCloudRemoveFileBlock)block{
	return [KRiCloudService removeAllFilesUsingBlock:block];
}

-(id)init{
	self = [super init];
	if(self){
		_preferences = [[KRCloudPreferences alloc]init];
		_factory = [[KRiCloudFactory alloc]init];
	}
	return self;
}

-(id)initWithFactory:(KRCloudFactory*)factory{
	self = [super init];
	if(self){
		_factory = factory;
	}
	return self;
}

-(KRCloudService*)service{
	return _factory.cloudService;
}


-(BOOL)sync{
	return YES;
}

-(BOOL)syncUsingBlock:(KRCloudSyncCompletedBlock)completedBlock{
	return [self syncUsingBlocks:nil progressBlock:nil completedBlock:completedBlock];
}

-(BOOL)syncUsingBlocks:(KRCloudSyncStartBlock)startBlock
		 progressBlock:(KRCloudSyncProgressBlock)progressBlock
		completedBlock:(KRCloudSyncCompletedBlock)completedBlock{
	NSAssert(completedBlock, @"Mustn't be nil");
	NSAssert(_factory, @"Mustn't be nil");
	if(!completedBlock || !_factory)
		return NO;
	
	KRResourceLoader* resourceLoader = [[KRResourceLoader alloc]initWithFactory:_factory];
	[resourceLoader loadUsingBlock:^(NSArray* remoteResources, NSArray* localResources, NSError* error){
		if(error){
			completedBlock(nil, error);
			return;
		}
		
		KRResourceComparer* resourceComparer = [[KRResourceComparer alloc]initWithFactory:_factory];
		NSArray* syncItems = [resourceComparer compare:localResources
									   remoteResources:remoteResources];
		if(startBlock){
			startBlock(syncItems);
		}
		 
		KRSynchronizer* sync = [[KRSynchronizer alloc]initWithFactory:_factory];
		[sync syncUsingBlock:syncItems progressBlock:progressBlock completedBlock:completedBlock];
	}];
	
	return YES;
}

@end
