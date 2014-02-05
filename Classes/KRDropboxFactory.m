//
//  KRDropboxFactory.m
//  CloudSync
//
//  Created by allting on 1/29/14.
//  Copyright (c) 2014 allting. All rights reserved.
//

#import "KRDropboxFactory.h"
#import "KRDropboxService.h"
#import "KRLocalFileService.h"

@implementation KRDropboxFactory

-(id)initWithDocumentsPaths:(NSString*)localDocumentsPath remote:(NSString*)remoteDocumentsPath filter:(NSArray*)filters cloudServiceDelegate:(id)delegate{
	self = [super init];
	if(self){
		KRResourceExtensionFilter* filter = [[KRResourceExtensionFilter alloc]initWithFilters:filters];
		KRDropboxService* cloudService = [[KRDropboxService alloc]initWithDocumentsPaths:localDocumentsPath remote:remoteDocumentsPath filter:filter];
		cloudService.delegate = delegate;
		self.cloudService = cloudService;
		self.fileService = [[KRLocalFileService alloc]initWithDocumentsPaths:localDocumentsPath remote:remoteDocumentsPath filter:filter];
	}
	return self;
}

@end
