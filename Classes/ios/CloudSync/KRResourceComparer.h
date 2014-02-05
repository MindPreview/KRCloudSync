//
//  KRResourceComparer.h
//  CloudSync
//
//  Created by allting on 12. 10. 14..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRCloudFactory.h"

typedef void (^KRResourceComparerCompletedBlock)(NSArray* comparedResources, NSError* error);

@interface KRResourceComparer : NSObject

-(id)initWithFactory:(KRCloudFactory*)factory;

-(NSArray*)compare:(NSArray*)localResources
   remoteResources:(NSArray*)remoteResources;

@end
