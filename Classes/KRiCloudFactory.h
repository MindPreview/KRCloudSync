//
//  KRiCloudFactory.h
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRCloudFactory.h"

@interface KRiCloudFactory : KRCloudFactory

-(id)initWithLocalPath:(NSString*)path filters:(NSArray*)filters cloudServiceDelegate:(id)delegate;

@end
