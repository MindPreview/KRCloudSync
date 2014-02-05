//
//  CloudPreferencesTests.m
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "CloudPreferencesTests.h"
#import "KRCloudSync.h"
#import "KRCloudPreferences.h"

@implementation CloudPreferencesTests

-(void)testCreation{
	KRCloudSync* cloudSync = [[KRCloudSync alloc]init];
	KRCloudPreferences* prefs = [cloudSync preferences];
	XCTAssertNotNil(prefs, @"Mustn't be nil");
}

@end
