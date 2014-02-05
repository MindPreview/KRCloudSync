//
//  KRiCloudResourceManager.h
//  CloudSync
//
//  Created by allting on 12. 10. 11..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRResourceProperty.h"

@interface KRiCloudResourceManager : NSObject

@property (nonatomic) NSArray* URLs;
@property (nonatomic) NSArray* Resources;

+(BOOL)isEqualToURL:(NSURL*)url otherURL:(NSURL*)otherURL;

-(id)initWithURLsAndProperties:(NSArray*)Resources;

-(BOOL)hasResource:(NSURL*)url;

-(KRResourceProperty*)findResource:(NSURL*)url;
-(BOOL)isModified:(KRResourceProperty *)resource anotherResource:(KRResourceProperty*)anotherResource;

@end
