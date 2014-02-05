//
//  KRResourceComparer.m
//  CloudSync
//
//  Created by allting on 12. 10. 14..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRResourceComparer.h"
#import "KRiCloudResourceManager.h"
#import "KRSyncItem.h"
#import "KRFileService.h"

@interface KRResourceComparer()
@property (nonatomic) KRFileService* fileService;
@property (nonatomic) KRCloudService* cloudService;
@property (nonatomic) NSDate* lastSyncTime;
@end

@implementation KRResourceComparer

-(id)initWithFactory:(KRCloudFactory*)factory{
	self = [super init];
	if(self){
        self.fileService = factory.fileService;
        self.cloudService = factory.cloudService;
        self.lastSyncTime = factory.lastSyncTime;
	}
	return self;
}

-(NSArray*)compare:(NSArray*)localResources
   remoteResources:(NSArray*)remoteResources{
	return [self compareResourcesAndCreateSyncItems:localResources remoteResources:remoteResources];
}

-(NSArray*)compareResourcesAndCreateSyncItems:(NSArray*)localResources remoteResources:(NSArray*)remoteResources{
	NSSet* keyResources = [self createKeyResources:localResources remoteResources:remoteResources];
	
	NSMutableArray* syncItems = [NSMutableArray arrayWithCapacity:[remoteResources count]];

	for(NSString* key in keyResources){
		KRResourceProperty* localResource = [self findResourceWithKeyInResources:key resources:localResources basePath:[self.fileService localDocumentsPath]];
		KRResourceProperty* remoteResource = [self findResourceWithKeyInResources:key resources:remoteResources basePath:[self.cloudService remoteDocumentsPath]];
		KRSyncItemAction action = KRSyncItemActionNone;
		if(!localResource){
			action = KRSyncItemActionRemoteAccept;
            localResource = [self.fileService createLocalResourceFromRemoteResource:remoteResource];
		}else if(!remoteResource){
            if(!self.lastSyncTime){
                // 동기화된 적이 없는 경우, 로컬 파일을 추가함.
                action = KRSyncItemActionAddToRemote;
            }else{
                NSDate* modifiedDate = [localResource modifiedDate];
                NSComparisonResult result = [self.lastSyncTime compare:modifiedDate];
                if(NSOrderedAscending == result){
                    // 동기화 이후에 수정된 경우, 로컬 파일을 추가함.
                    action = KRSyncItemActionAddToRemote;
                }else{
                    // 동기화 이전에 수정된 경우, (다른 디바이스에서 리모트 파일이 삭제된 경우) 제거함.
                    action = KRSyncItemActionRemoveInLocal;
                }
            }
        }else{
			action = [localResource compare:remoteResource];
        }
		
		KRSyncItem* item = [[KRSyncItem alloc]initWithResources:localResource
												 remoteResource:remoteResource
                                                     syncAction:action];
		[syncItems addObject:item];
	}
	
	return syncItems;
}

-(NSSet*)createKeyResources:(NSArray*)localResources remoteResources:(NSArray*)remoteResources{
	NSMutableSet* keys = [NSMutableSet setWithCapacity:[localResources count]+[remoteResources count]];
	for(KRResourceProperty* res in localResources){
		NSString* key = [res pathByDeletingSubPath:[self.fileService localDocumentsPath]];
		[keys addObject:key];
	}
	
	for(KRResourceProperty* res in remoteResources){
		NSString* key = [res pathByDeletingSubPath:[self.cloudService remoteDocumentsPath]];
		[keys addObject:key];
	}
	return keys;
}

-(KRResourceProperty*)findResourceWithKeyInResources:(NSString*)key resources:(NSArray*)resources basePath:(NSString*)basePath{
	for(KRResourceProperty* resource in resources){
		NSString* name = [resource pathByDeletingSubPath:basePath];
		if([key isEqualToString:name])
			return resource;
	}
	return nil;
}

-(KRSyncItem*)compareResourceAndCreateSyncItem:(KRResourceProperty*)localResource
						 remoteResource:(KRResourceProperty*)remoteResource{
	if([KRiCloudResourceManager isEqualToURL:localResource.URL otherURL:remoteResource.URL]){
		KRSyncItemAction action = [localResource compare:remoteResource];
		if(action!=KRSyncItemActionNone){
			return [[KRSyncItem alloc]initWithResources:localResource
                                         remoteResource:remoteResource
                                             syncAction:action];
		}
	}
	return nil;
}

@end
