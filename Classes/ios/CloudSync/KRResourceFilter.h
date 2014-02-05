//
//  KRResourceFilter.h
//  CloudSync
//
//  Created by allting on 12. 11. 18..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KRResourceFilter : NSObject

-(NSPredicate*)createPredicate;
-(BOOL)shouldPass:(NSString*)path;

@end


@interface KRResourceExtensionFilter : KRResourceFilter
@property (nonatomic) NSArray* filters;

-(id)initWithFilters:(NSArray*)filters;

-(NSPredicate*)createPredicate;
-(BOOL)shouldPass:(NSString*)path;

@end