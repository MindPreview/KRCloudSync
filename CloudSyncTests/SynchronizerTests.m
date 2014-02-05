//
//  SynchronizerTests.m
//  CloudSync
//
//  Created by allting on 12. 10. 19..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "SynchronizerTests.h"
#import "KRSyncItem.h"

@implementation SynchronizerTests

-(void)testSynchronizer{
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* localResources = [factory createModifiedLocalResources];
	NSArray* remoteResources = [factory createRemoteResources];
	NSArray* syncItems = [factory createSyncItems:localResources remoteResources:remoteResources];
	
	KRSynchronizer* sync = [[KRSynchronizer alloc]initWithFactory:factory];
	[sync syncUsingBlock:syncItems progressBlock:^(KRSyncItem *synItem, float progress) {
	} completedBlock:^(NSArray *syncResources, NSError *error) {
		XCTAssertNil(error, @"Must be nil");
		for(KRSyncItem* item in syncItems){
			XCTAssertEqual([item result], KRSyncItemResultCompleted, @"Must be equal");
		}
	}];
}

/*
-(void)testSynchronizerConflict{
	CloudFactoryMock* factory = [[CloudFactoryMock alloc]init];
	NSArray* localResources = [factory createLocalResourcesWithModifiedTimeInterval:3];
	NSArray* remoteResources = [factory createRemoteResourcesWithModifiedTimeInterval:5];
	NSArray* syncItems = [factory createSyncItems:localResources remoteResources:remoteResources];
	
	KRSynchronizer* sync = [[KRSynchronizer alloc]initWithFactory:factory];
	[sync syncUsingBlock:syncItems completedBlock:^(NSArray* syncItems, NSError* error){
		STAssertNotNil(error, @"Mustn't be nil");
		for(KRSyncItem* item in syncItems){
			STAssertEquals([item result], KRSyncItemResultConflicted, @"Must be equal");
		}
	}];
}
*/
@end
