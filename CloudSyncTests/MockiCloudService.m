//
//  iCloudServiceMock.m
//  CloudSync
//
//  Created by allting on 12. 10. 12..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "MockiCloudService.h"
#import "KRSyncItem.h"
#import "KRResourceProperty.h"

@implementation MockiCloudService
@synthesize resources = _resources;

-(NSArray*)resources{
    if(_resources)
        return _resources;
    
    struct RESOURCE{
        char* url;
        int createAtInterval;
        int modifiedAtInterval;
        NSUInteger size;
    }res[] = {
        {"/test/test1.zip", -1000, 3000, 1000000},
        {"/test/test2.zip", -1000, 5000, 1000000},
        {"/test/test3.zip", -1000, 5000, 1000000}
    };
    
    size_t size = sizeof res / sizeof res[1];
    
    NSMutableArray* resources = [NSMutableArray arrayWithCapacity:size];
    for(size_t i=0; i<size; i++){
        NSURL* url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:res[i].url]];
        NSDate* createdAt = [NSDate dateWithTimeIntervalSinceNow:res[i].createAtInterval];
        NSDate* modifiedAt = [NSDate dateWithTimeIntervalSinceNow:res[i].modifiedAtInterval];
        NSNumber* fileSize = [NSNumber numberWithUnsignedInteger:res[i].size];
        
        KRResourceProperty* resource = [[KRResourceProperty alloc] initWithProperties:url
                                                                          createdDate:createdAt
                                                                         modifiedDate:modifiedAt
                                                                                 size:fileSize];
        [resources addObject:resource];
    }
    
    _resources = [NSArray arrayWithArray:resources];
    return _resources;
}

-(BOOL)loadResourcesUsingBlock:(KRResourcesCompletedBlock)completed{
    completed(self.resources, nil);
    return YES;
}

-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRSynchronizerCompletedBlock)completed{
	NSAssert(completed, @"Mustn't be nil");
	if(!completed)
		return NO;
	
	for(KRSyncItem* item in syncItems){
		item.result = KRSyncItemResultCompleted;
	}
	
	completed(syncItems, nil);
	return YES;
}

@end
