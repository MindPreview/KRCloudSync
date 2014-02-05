//
//  ResourceComparerTest.m
//  CloudSync
//
//  Created by allting on 12. 10. 14..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "ResourceComparerTest.h"
#import "KRResourceComparer.h"
#import "KRCloudFactory.h"
#import "KRResourceProperty.h"
#import "KRResourceLoader.h"
#import "KRSyncItem.h"

#import "MockCloudFactory.h"

@implementation ResourceComparerTest

-(void)testResourceComparer{
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createRemoteResources];
	NSArray* localResources = [factory createLocalResources];
	
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
				 
	XCTAssertTrue([remoteResources count]==[syncItems count], @"Must be equal");
}

-(void)testLocalResourceModified{
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createRemoteResources];
	NSArray* localResources = [factory createModifiedLocalResources];
	
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue([localResources count]==[syncItems count], @"Must be equal");
	for(KRSyncItem* item in syncItems){
		XCTAssertEqual([item action], KRSyncItemActionLocalAccept, @"Must be equal to RemoteDirection");
	}
}

-(void)testRemoteResourceModified{
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createModifiedRemoteResources];
	NSArray* localResources = [factory createLocalResources];
	
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue([localResources count]==[syncItems count], @"Must be equal");
	for(KRSyncItem* item in syncItems){
		XCTAssertEqual([item action], KRSyncItemActionRemoteAccept, @"Must be equal to LocalDirection");
	}
}

-(void)testWithEmptyRemoteResouces{
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createEmptyResources];
	NSArray* localResources = [factory createLocalResources];
	
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue([localResources count]==[syncItems count], @"Must be equal");
	for(KRSyncItem* item in syncItems){
		XCTAssertEqual([item action], KRSyncItemActionAddToRemote, @"Must be equal to LocalDirection");
	}
}

-(void)testWithEmptyLocalResouces{
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createRemoteResources];
	NSArray* localResources = [factory createEmptyResources];
	
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue([remoteResources count]==[syncItems count], @"Must be equal");
	for(KRSyncItem* item in syncItems){
		XCTAssertEqual([item action], KRSyncItemActionRemoteAccept, @"Must be equal to RemoteResources");
	}
}

-(void)testResoucesCount{
    NSUInteger kCOUNT = 5;
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createResourcesWithDocumentsPath:[factory.cloudService remoteDocumentsPath] count:kCOUNT];
	NSArray* localResources = [factory createResourcesWithDocumentsPath:[factory.fileService localDocumentsPath] count:kCOUNT];
	
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue(kCOUNT==[syncItems count], @"Must be equal");
	for(KRSyncItem* item in syncItems){
		XCTAssertEqual([item action], KRSyncItemActionNone, @"Must be equal to LocalDirection");
	}
}

-(void)testRemoteResoucesCountGreaterThanLocal{
    NSUInteger kREMOTE_COUNT = 7;
    NSUInteger kLOCAL_COUNT = 5;
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createResourcesWithDocumentsPath:[factory.cloudService remoteDocumentsPath] count:kREMOTE_COUNT];
	NSArray* localResources = [factory createResourcesWithDocumentsPath:[factory.fileService localDocumentsPath] count:kLOCAL_COUNT];
	
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue(kREMOTE_COUNT==[syncItems count], @"Must be equal");
    
    NSUInteger syncNoneCount = 0;
    NSUInteger syncToLocalCount = 0;
	for(KRSyncItem* item in syncItems){
        if(KRSyncItemActionNone == [item action])
            syncNoneCount++;
        if(KRSyncItemActionRemoteAccept == [item action])
            syncToLocalCount++;
	}
    
    XCTAssertEqual(kLOCAL_COUNT, syncNoneCount, @"Must be equal");
    XCTAssertEqual(kREMOTE_COUNT-kLOCAL_COUNT, syncToLocalCount, @"Must be equal");
}

-(void)testLocalGreaterResoucesCountThanRemote{
    NSUInteger kREMOTE_COUNT = 5;
    NSUInteger kLOCAL_COUNT = 8;
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createResourcesWithDocumentsPath:[factory.cloudService remoteDocumentsPath] count:kREMOTE_COUNT];
	NSArray* localResources = [factory createResourcesWithDocumentsPath:[factory.fileService localDocumentsPath] count:kLOCAL_COUNT];
	
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue(kLOCAL_COUNT==[syncItems count], @"Must be equal");
    
    NSUInteger syncNoneCount = 0;
    NSUInteger syncRemoteCount = 0;
	for(KRSyncItem* item in syncItems){
        if(KRSyncItemActionNone == [item action])
            syncNoneCount++;
        if(KRSyncItemActionAddToRemote == [item action])
            syncRemoteCount++;
	}
    
    XCTAssertEqual(kREMOTE_COUNT, syncNoneCount, @"Must be equal");
    XCTAssertEqual(kLOCAL_COUNT-kREMOTE_COUNT, syncRemoteCount, @"Must be equal to a count in local only");
}

-(void)testLocalGreaterResoucesCountThanRemoteWithLastSyncTimeBefore{
    NSUInteger kREMOTE_COUNT = 5;
    NSUInteger kLOCAL_COUNT = 8;
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createResourcesWithDocumentsPath:[factory.cloudService remoteDocumentsPath] count:kREMOTE_COUNT];
	NSArray* localResources = [factory createResourcesWithDocumentsPath:[factory.fileService localDocumentsPath] count:kLOCAL_COUNT];
	
    NSDate* lastSyncTime = [NSDate dateWithTimeIntervalSinceNow:-5];
    [factory setLastSyncTime:lastSyncTime];
    
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue(kLOCAL_COUNT==[syncItems count], @"Must be equal");
    
    NSUInteger syncNoneCount = 0;
    NSUInteger syncLocalCount = 0;
	for(KRSyncItem* item in syncItems){
        if(KRSyncItemActionNone == [item action])
            syncNoneCount++;
        if(KRSyncItemActionAddToRemote == [item action])
            syncLocalCount++;
	}
    
    XCTAssertEqual(kREMOTE_COUNT, syncNoneCount, @"Must be equal");
    XCTAssertEqual(kLOCAL_COUNT-kREMOTE_COUNT, syncLocalCount, @"Must be equal to a count in local only");
}

// 리모트와 개수가 작고,
// 동기화를 수행한 적이 있고(마지막 동기화 시간을 가지고),
// 동기화 시간 이전에 수정된 경우.
// -> 리모트가 적용되어 삭제되어야 함.
-(void)testLocalGreaterResoucesCountThanRemoteWithLastSyncTimeLater{
    NSUInteger kREMOTE_COUNT = 5;
    NSUInteger kLOCAL_COUNT = 8;
	MockCloudFactory* factory = [[MockCloudFactory alloc]init];
	NSArray* remoteResources = [factory createResourcesWithDocumentsPath:[factory.cloudService remoteDocumentsPath] count:kREMOTE_COUNT];
	NSArray* localResources = [factory createResourcesWithDocumentsPath:[factory.fileService localDocumentsPath] count:kLOCAL_COUNT];
	
    NSDate* lastSyncTime = [NSDate dateWithTimeIntervalSinceNow:10];
    [factory setLastSyncTime:lastSyncTime];
    
	KRResourceComparer* comparer = [[KRResourceComparer alloc]initWithFactory:factory];
	XCTAssertNotNil(comparer, @"Mustn't be nil");
	
	NSArray* syncItems = [comparer compare:localResources
						   remoteResources:remoteResources];
	XCTAssertTrue(kLOCAL_COUNT==[syncItems count], @"Must be equal");
    
    NSUInteger syncNoneCount = 0;
    NSUInteger syncRemoveCount = 0;
	for(KRSyncItem* item in syncItems){
        if(KRSyncItemActionNone == [item action])
            syncNoneCount++;
        if(KRSyncItemActionRemoveInLocal == [item action])
            syncRemoveCount++;
	}
    
    XCTAssertEqual(kREMOTE_COUNT, syncNoneCount, @"Must be equal");
    XCTAssertEqual(kLOCAL_COUNT-kREMOTE_COUNT, syncRemoveCount, @"Must be equal to a count in local only");
}

@end
