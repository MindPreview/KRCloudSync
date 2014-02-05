//
//  KRResourceLoader.h
//  CloudSync
//
//  Created by allting on 12. 10. 14..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRCloudFactory.h"

typedef void (^KRResourceLoaderCompletedBlock)(NSArray* remoteResources, NSArray* localResources, NSError* error);

@interface KRResourceLoader : NSObject

@property (nonatomic) KRCloudService* cloudService;
@property (nonatomic) KRFileService* fileService;
@property (nonatomic) NSArray* remoteResources;
@property (nonatomic) NSArray* localResources;

-(id)initWithFactory:(KRCloudFactory*)factory;

-(BOOL)load;
-(BOOL)loadUsingBlock:(KRResourceLoaderCompletedBlock)completed;

@end
