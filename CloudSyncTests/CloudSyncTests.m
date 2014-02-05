//
//  CloudSyncTests.m
//  CloudSyncTests
//
//  Created by allting on 2/5/14.
//  Copyright (c) 2014 allting. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KRCloudSync.h"
#import "MockCloudFactory.h"
#import "MockiCloudService.h"

@interface CloudSyncTests : XCTestCase

@end

@implementation CloudSyncTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCloudSync
{
	KRCloudSync* cloudSync = [[KRCloudSync alloc]init];
    XCTAssertTrue([cloudSync sync], @"Test sync method");
}

-(void)testSimpleSync{
	KRCloudFactory* factory = [self createiCloudMockFactory];
	KRCloudSync* cloudSync = [[KRCloudSync alloc]initWithFactory:factory];
	
	[cloudSync syncUsingBlock:^(NSArray* syncItems, NSError* error){
        NSLog(@"syncUsingBlock-syncItems:%@, error:%@", syncItems, error);
        
        MockiCloudService* service = (MockiCloudService*)[factory cloudService];
        NSAssert(service, @"Mustn't be nil");
        
        NSArray* resources = [service resources];
        XCTAssertTrue([resources count] == [syncItems count], @"Must be equal");
	}];
}

-(KRCloudFactory*)createiCloudMockFactory{
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	return factory;
}


@end
