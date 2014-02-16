//
//  KRSyncItem.h
//  CloudSync
//
//  Created by allting on 12. 10. 15..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, KRSyncItemAction) {
	KRSyncItemActionNone,
	KRSyncItemActionRemoteAccept,
	KRSyncItemActionLocalAccept,
    KRSyncItemActionAddToRemote,
    KRSyncItemActionRemoveRemoteItem,
    KRSyncItemActionRemoveInLocal
};

typedef enum {
	KRSyncItemResultNone,
	KRSyncItemResultCompleted,
	KRSyncItemResultConflicted
}KRSyncItemResult;

@class KRResourceProperty;

@interface KRSyncItem : NSObject

@property (nonatomic, assign) KRSyncItemAction action;
@property (nonatomic) KRResourceProperty* localResource;
@property (nonatomic) KRResourceProperty* remoteResource;
@property (nonatomic, assign) KRSyncItemResult result;
@property (nonatomic) NSError* error;

-(id)initWithResources:(KRResourceProperty*)localResource
		remoteResource:(KRResourceProperty*)remoteResource
            syncAction:(KRSyncItemAction)action;

-(NSString*)description;

@end
