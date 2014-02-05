//
//  KRDropboxFactory.h
//  CloudSync
//
//  Created by allting on 1/29/14.
//  Copyright (c) 2014 allting. All rights reserved.
//

#import "KRCloudFactory.h"

@interface KRDropboxFactory : KRCloudFactory

-(id)initWithDocumentsPaths:(NSString*)localDocumentsPath remote:(NSString*)remoteDocumentsPath filter:(NSArray*)filters cloudServiceDelegate:(id)delegate;

@end
