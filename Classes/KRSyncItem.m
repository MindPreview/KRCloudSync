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

-(NSURL*)remoteURL{
    return [_remoteResource URL];
}

-(NSString*)remotePath{
    return [[_remoteResource URL] path];
}

-(NSString*)localPath{
    return [[_localResource URL] path];
}

-(NSURL*)localURL{
    return [_localResource URL];
}

-(NSString*)description{
	NSString* action = [self stringFromAction];
	
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

-(NSString*)stringFromAction{
    NSString* action = @"Unknown";
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
        case KRSyncItemActionRemoveRemoteItem:
            action = @"RemoveFromRemote";
            break;
        case KRSyncItemActionRemoveInLocal:
            action = @"RemoveInLocal";
            break;
        default:
            break;
    }
    return action;
}

@end
