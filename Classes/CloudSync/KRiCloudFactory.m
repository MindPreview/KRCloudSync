//
//  KRiCloudFactory.m
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRiCloudFactory.h"
#import "KRiCloudService.h"
#import "KRLocalFileService.h"

@implementation KRiCloudFactory

-(id)init{
	self = [super init];
	if(self){
		self.cloudService = [[KRiCloudService alloc]init];
		self.fileService = [[KRLocalFileService alloc]init];
	}
	return self;
}

-(id)initWithLocalPath:(NSString*)path filters:(NSArray*)filters cloudServiceDelegate:(id)delegate{
	self = [super init];
	if(self){
		KRResourceExtensionFilter* filter = [[KRResourceExtensionFilter alloc]initWithFilters:filters];
		KRiCloudService* cloudService = [[KRiCloudService alloc]initWithDocumentsPath:path filter:filter];
		cloudService.delegate = delegate;
		self.cloudService = cloudService;
		self.fileService = [[KRLocalFileService alloc]initWithDocumentsPaths:path remote:@"/" filter:filter];
	}
	return self;
}


@end
