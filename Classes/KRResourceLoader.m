//
//  KRResourceLoader.m
//  CloudSync
//
//  Created by allting on 12. 10. 14..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRResourceLoader.h"

@implementation KRResourceLoader

-(id)initWithFactory:(KRCloudFactory*)factory{
	self = [super init];
	if(self){
		_cloudService = factory.cloudService;
		_fileService = factory.fileService;
	}
	return self;
}

-(BOOL)load{
	NSAssert(_cloudService, @"Mustn't be nil");
	NSAssert(_fileService, @"Mustn't be nil");
	if(!_cloudService || !_fileService)
		return NO;
	
	return YES;
}

-(BOOL)loadUsingBlock:(KRResourceLoaderCompletedBlock)completed{
	NSAssert(completed, @"Mustn't be nil");
	NSAssert(_cloudService, @"Mustn't be nil");
	NSAssert(_fileService, @"Mustn't be nil");
	if(!completed || !_cloudService || !_fileService)
		return NO;
	
	NSArray* localResources = [_fileService load];
	[_cloudService loadResourcesUsingBlock:^(NSArray* remoteResources, NSError* error){
		completed(remoteResources, localResources, error);
	}];
	return YES;
}

@end
