//
//  ResourceFilterTests.m
//  CloudSync
//
//  Created by allting on 12. 11. 18..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "ResourceFilterTests.h"
#import "KRResourceFilter.h"

@implementation ResourceFilterTests

-(void)testResourceFilter{
	NSString* TEST_PATH = @"/User/test/test.png";
	
	KRResourceFilter* filter = [[KRResourceFilter alloc]init];
	
	XCTAssertTrue([filter shouldPass:TEST_PATH], @"Must be passed");
}

-(void)testResourceExtensionFilter{
	NSString* TEST_PATH = @"/User/test/test.png";
	
	NSArray* filters = @[@"*"];
	KRResourceFilter* filter = [[KRResourceExtensionFilter alloc]initWithFilters:filters];
	
	// Should use KRResourceFilter for all files.
	XCTAssertFalse([filter shouldPass:TEST_PATH], @"Mustn't be passed");
}

-(void)testResourceExtensionFilterWithExtensions{
	NSString* TEST_PASS_PATH = @"/User/test/test.png";
	NSString* TEST_PASS_PATH1 = @"/user/test/test.jpg";
	NSString* TEST_SHOULD_NOT_PASS_PATH = @"/user/test/test.zip";
	NSString* TEST_SHOULD_NOT_PASS_PATH1 = @"/user/test/test";
	NSString* TEST_SHOULD_NOT_PASS_PATH2 = @"/user/test/test/";
	
	NSArray* filters = @[@"jpg", @"png"];
	KRResourceFilter* filter = [[KRResourceExtensionFilter alloc]initWithFilters:filters];
	
	XCTAssertTrue([filter shouldPass:TEST_PASS_PATH], @"Must be passed");
	XCTAssertTrue([filter shouldPass:TEST_PASS_PATH1], @"Must be passed");
	XCTAssertFalse([filter shouldPass:TEST_SHOULD_NOT_PASS_PATH], @"Mustn't be passed");
	XCTAssertFalse([filter shouldPass:TEST_SHOULD_NOT_PASS_PATH1], @"Mustn't be passed");
	XCTAssertFalse([filter shouldPass:TEST_SHOULD_NOT_PASS_PATH2], @"Mustn't be passed");
}

@end
