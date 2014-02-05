//
//  CloudFactoryMock.m
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "MockCloudFactory.h"
#import "MockiCloudService.h"
#import "MockFileService.h"
#import "KRResourceProperty.h"
#import "KRSyncItem.h"
#import "KRiCloudResourceManager.h"

@interface MockCloudFactory()
@property (nonatomic) NSString* localDocumentsPath;
@property (nonatomic) NSString* remoteDocumentsPath;
@end

@implementation MockCloudFactory

-(id)init{
	self = [super init];
	if(self){
        self.localDocumentsPath = @"/Users/test/documents";
        self.remoteDocumentsPath = @"/System/private/test/documents";
		self.cloudService = [[MockiCloudService alloc]initWithDocumentsPaths:self.localDocumentsPath remote:self.remoteDocumentsPath];
		self.fileService = [[MockFileService alloc]initWithDocumentsPaths:self.localDocumentsPath remote:self.remoteDocumentsPath filter:nil];
	}
	return self;
}

-(NSArray*)createRemoteResources{
	return [self createRemoteResourcesWithModifiedTimeInterval:1];
}

-(NSArray*)createModifiedRemoteResources{
	return [self createRemoteResourcesWithModifiedTimeInterval:2];
}

-(NSArray*)createLocalResources{
	return [self createLocalResourcesWithModifiedTimeInterval:1];
}

-(NSArray*)createModifiedLocalResources{
	return [self createLocalResourcesWithModifiedTimeInterval:2];
}

-(NSArray*)createRemoteResourcesWithModifiedTimeInterval:(NSTimeInterval)interval{
	NSArray* TEST_URLS = [self createDefaultRemoteURLs];
	NSArray* TEST_CREATED_DATE = [self createDateArrayWithTimeInterval:1];
	NSArray* TEST_MODIFIED_DATE = [self createDateArrayWithTimeInterval:interval];
	NSArray* TEST_SIZES = [self createDefaultFileSize];
	
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:[TEST_URLS count]];
	for(NSInteger i=0; i<[TEST_URLS count]; i++){
		KRResourceProperty* resource = [[KRResourceProperty alloc]initWithProperties:[TEST_URLS objectAtIndex:i]
																		 createdDate:[TEST_CREATED_DATE objectAtIndex:i]
																		modifiedDate:[TEST_MODIFIED_DATE objectAtIndex:i]
																				size:[TEST_SIZES objectAtIndex:i]];
		
		[array addObject:resource];
	}
	return array;
}

-(NSArray*)createLocalResourcesWithModifiedTimeInterval:(NSTimeInterval)interval{
	NSArray* TEST_URLS = [self createDefaultLocalURLs];
	NSArray* TEST_CREATED_DATE = [self createDateArrayWithTimeInterval:1];
	NSArray* TEST_MODIFIED_DATE = [self createDateArrayWithTimeInterval:interval];
	NSArray* TEST_SIZES = [self createDefaultFileSize];
	
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:[TEST_URLS count]];
	for(NSInteger i=0; i<[TEST_URLS count]; i++){
		KRResourceProperty* resource = [[KRResourceProperty alloc]initWithProperties:[TEST_URLS objectAtIndex:i]
																		 createdDate:[TEST_CREATED_DATE objectAtIndex:i]
																		modifiedDate:[TEST_MODIFIED_DATE objectAtIndex:i]
																				size:[TEST_SIZES objectAtIndex:i]];
		
		[array addObject:resource];
	}
	return array;
}

-(NSArray*)createEmptyResources{
	return [NSArray array];
}

-(NSArray*)createDefaultRemoteURLs{
	NSArray* urls = @[
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.remoteDocumentsPath, @"test1.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.remoteDocumentsPath, @"test/test2.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.remoteDocumentsPath, @"test3.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.remoteDocumentsPath, @"test/test4.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.remoteDocumentsPath, @"test5.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.remoteDocumentsPath, @"test/test6.zip"]]
	];
	return urls;
}

-(NSArray*)createDefaultLocalURLs{
	NSArray* urls = @[
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.localDocumentsPath, @"test1.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.localDocumentsPath, @"test/test2.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.localDocumentsPath, @"test3.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.localDocumentsPath, @"test/test4.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.localDocumentsPath, @"test5.zip"]],
	[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.localDocumentsPath, @"test/test6.zip"]]
	];
	return urls;
}

-(NSArray*)createDateArrayWithTimeInterval:(NSTimeInterval)seconds{
	NSArray* date = @[
	[NSDate dateWithTimeIntervalSinceNow:seconds],
	[NSDate dateWithTimeIntervalSinceNow:seconds+1],
	[NSDate dateWithTimeIntervalSinceNow:seconds+2],
	[NSDate dateWithTimeIntervalSinceNow:seconds+3],
	[NSDate dateWithTimeIntervalSinceNow:seconds+4],
	[NSDate dateWithTimeIntervalSinceNow:seconds+5]
	];
	return date;
}

-(NSArray*)createDefaultFileSize{
	NSArray* sizes = @[
	[NSNumber numberWithInteger:20000],
	[NSNumber numberWithInteger:30000],
	[NSNumber numberWithInteger:40000],
	[NSNumber numberWithInteger:50000],
	[NSNumber numberWithInteger:60000],
	[NSNumber numberWithInteger:70000]
	];
	return sizes;
}

-(NSArray*)createSyncItems:(NSArray*)localResources remoteResources:(NSArray*)remoteResources{
	return [self compareResourcesAndCreateSyncItems:localResources remoteResources:remoteResources];
}

-(NSArray*)compareResourcesAndCreateSyncItems:(NSArray*)localResources remoteResources:(NSArray*)remoteResources{
	NSMutableArray* syncItems = [NSMutableArray arrayWithCapacity:[remoteResources count]];
	
	for(KRResourceProperty* resource in localResources){
		for(KRResourceProperty* remoteResource in remoteResources){
			[self compareResourceAndCreateSyncItem:resource remoteResource:remoteResource array:syncItems];
		}
	}
	
	return syncItems;
}

-(void)compareResourceAndCreateSyncItem:(KRResourceProperty*)localResource
						 remoteResource:(KRResourceProperty*)remoteResource
								  array:(NSMutableArray*)syncItems{
	if([KRiCloudResourceManager isEqualToURL:localResource.URL otherURL:remoteResource.URL]){
		KRSyncItemAction action = [localResource compare:remoteResource];
		if(action!=KRSyncItemActionNone){
			KRSyncItem* item = [[KRSyncItem alloc]initWithResources:localResource
													 remoteResource:remoteResource
                                                         syncAction:action];
			[syncItems addObject:item];
		}
	}
}

-(NSArray*)resourcesWithPath:(NSString*)path{
    NSUInteger kCOUNT = 10;
    NSString* baseURLString = path;
    
    NSMutableArray* resources = [[NSMutableArray alloc]initWithCapacity:10];
    
    for(NSUInteger i=0; i<kCOUNT; i++){
        NSString* fileName = [NSString stringWithFormat:@"test%d.zip", i+1];
        NSString* urlString = [baseURLString stringByAppendingPathComponent:fileName];
        NSURL* url = [NSURL URLWithString:urlString];
        
        NSDictionary* dic = @{
                              @"url":url,
                              @"createdAt":[NSDate dateWithTimeIntervalSinceNow:0],
                              @"modifiedAt":[NSDate dateWithTimeIntervalSinceNow:0],
                              @"size":[NSNumber numberWithInt:i+1*1000]
                              };
        [resources addObject:dic];
    }
    
    return resources;
}

-(NSArray*)createResourcesWithDocumentsPath:(NSString*)documentsPath count:(NSUInteger)count{
    NSMutableArray* resources = [NSMutableArray arrayWithCapacity:count];
    NSUInteger i=0;
    for(NSDictionary* dic in [self resourcesWithPath:documentsPath]){
        KRResourceProperty* resource = [[KRResourceProperty alloc]initWithProperties:[dic objectForKey:@"url"]
                                                                         createdDate:[dic objectForKey:@"createdAt"]
                                                                        modifiedDate:[dic objectForKey:@"modifiedAt"]
                                                                                size:[dic objectForKey:@"size"]];
        [resources addObject:resource];
        
        i++;
        if(count <= i)
            break;
    }
    
    return resources;
}

@end
