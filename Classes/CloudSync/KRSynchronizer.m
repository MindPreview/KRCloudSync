//
//  KRSynchronizer.m
//  CloudSync
//
//  Created by allting on 12. 10. 14..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRSynchronizer.h"

@implementation KRSynchronizer

-(id)initWithFactory:(KRCloudFactory*)factory{
	self = [super init];
	if(self){
		_cloudService = factory.cloudService;
	}
	return self;
}

-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRSynchronizerCompletedBlock)completed{
	NSAssert(_cloudService, @"Mustn't be nil");
	NSAssert(completed, @"Mustn't be nil");
	if(!_cloudService || !completed)
		return NO;

	return [_cloudService syncUsingBlock:syncItems
						   progressBlock:progressBlock
						  completedBlock:completed];
}

@end
