//
//  iCloudSyncTests.h
//  CloudSync
//
//  Created by allting on 12. 10. 11..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface iCloudSyncTests : XCTestCase

@property (nonatomic) NSArray* testResources;
@property (nonatomic) NSURL* testURL;
@property (nonatomic) NSURL* testShouldNotFoundURL;
@property (nonatomic) NSDate* testDate;
@property (nonatomic) NSNumber* testSize;

@end
