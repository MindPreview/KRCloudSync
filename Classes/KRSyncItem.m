//
//  KRSyncItem.m
//  CloudSync
//
//  Created by allting on 12. 10. 15..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRSyncItem.h"
#import "KRResourceProperty.h"

@implementation KRSyncItem

-(id)initWithResources:(KRResourceProperty*)localResource
		remoteResource:(KRResourceProperty*)remoteResource
            syncAction:(KRSyncItemAction)action{
	self = [super init];
	if(self){
		_localResource = localResource;
		_remoteResource = remoteResource;
		_action = action;
		_result = KRSyncItemResultNone;
	}
	return self;
}

-(NSString*)description{
	NSString* action = nil;
    switch (_action) {
        case KRSyncItemActionNone:
            action = @"None";
            break;
        case KRSyncItemActionLocalAccept:
            action = @"LocalAccept";
            break;
        case KRSyncItemActionRemoteAccept:
            action = @"RemoteAccept";
            break;
        case KRSyncItemActionAddToRemote:
            action = @"AddToRemote";
            break;
        case KRSyncItemActionRemoveInLocal:
            action = @"RemoveInLocal";
            break;
        default:
            break;
    }
	
	NSString* result = nil;
	if(KRSyncItemResultNone==_result)
		result = @"None";
	else if(KRSyncItemResultConflicted==_result)
		result = @"Conflicted";
	else
		result = @"Completed";
	
	return [NSString stringWithFormat:@"action:%@,result:%@,localResources:%@,remoteResources:%@, error:%@",
										action, result, _localResource, _remoteResource, _error];
}

@end
