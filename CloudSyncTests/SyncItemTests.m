//
//  SyncItemTests.m
//  CloudSync
//
//  Created by allting on 12. 10. 15..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "SyncItemTests.h"
#import "KRSyncItem.h"
#import "KRResourceProperty.h"

@implementation SyncItemTests

-(void)testSyncItemCreate{
	KRSyncItem* syncItem = [[KRSyncItem alloc]init];
	XCTAssertEqual(KRSyncItemActionNone, syncItem.action, @"Must be equal to direction of syncItem");
}

-(void)testSyncItemWithResources{
	KRResourceProperty* localResource = [self createLocalResource];
	KRResourceProperty* remoteResource = [self createRemoteResource];

	KRSyncItemAction action = [localResource compare:remoteResource];
	KRSyncItem* syncItem = [[KRSyncItem alloc]initWithResources:localResource
                                                 remoteResource:remoteResource
                                                     syncAction:action];
	XCTAssertEqual(KRSyncItemActionNone, syncItem.action, @"Must be equal to direction of syncItem");
}

-(KRResourceProperty*)createLocalResource{
	NSURL* TEST_URL = [NSURL fileURLWithPath:@"/user/test/test.zip"];
	NSDate* TEST_DATE = [NSDate date];
	NSNumber* TEST_SIZE = [NSNumber numberWithInteger:23840];
	
	return [[KRResourceProperty alloc]initWithProperties:TEST_URL
											 createdDate:TEST_DATE
											modifiedDate:TEST_DATE
													size:TEST_SIZE];
}

-(KRResourceProperty*)createRemoteResource{
	NSURL* TEST_URL = [NSURL fileURLWithPath:@"/private/test/test.zip"];
	NSDate* TEST_DATE = [NSDate date];
	NSNumber* TEST_SIZE = [NSNumber numberWithInteger:23840];
	
	return [[KRResourceProperty alloc]initWithProperties:TEST_URL
											 createdDate:TEST_DATE
											modifiedDate:TEST_DATE
													size:TEST_SIZE];
}

@end
