//
//  KRCloudFactory.m
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRCloudFactory.h"

@implementation KRCloudFactory

-(id)init{
	self = [super init];
	if(self){
		self.cloudService = [[KRCloudService alloc]init];
		self.fileService = [[KRFileService alloc]init];
		self.filter = [[KRResourceFilter alloc]init];
	}
	return self;
}

@end
