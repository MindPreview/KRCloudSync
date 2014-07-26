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

-(id)initWithDocumentsPath:(NSString*)path filters:(NSArray*)filters cloudServiceDelegate:(id)delegate{
	self = [super init];
	if(self){
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *ubiquityContainer = [fileManager URLForUbiquityContainerIdentifier:nil];
        NSAssert([[ubiquityContainer path] length], @"Must have remote path");
        
        NSString* remotePath = [[ubiquityContainer path] stringByAppendingPathComponent:@"Documents"];

		KRResourceExtensionFilter* filter = [[KRResourceExtensionFilter alloc]initWithFilters:filters];
		KRiCloudService* cloudService = [[KRiCloudService alloc]initWithDocumentsPath:path remote:remotePath filter:filter];
		cloudService.delegate = delegate;
		self.cloudService = cloudService;
		self.fileService = [[KRLocalFileService alloc]initWithDocumentsPaths:path remote:remotePath filter:filter];
	}
	return self;
}


@end
