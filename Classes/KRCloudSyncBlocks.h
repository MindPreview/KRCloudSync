//
//  KRCloudSyncBlocks.h
//  CloudSync
//
//  Created by allting on 12. 10. 19..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#ifndef CloudSync_KRCloudSyncBlocks_h
#define CloudSync_KRCloudSyncBlocks_h

@class KRSyncItem;

typedef void (^KRCloudSyncStartBlock)(NSArray* syncItems);
typedef void (^KRCloudSyncProgressBlock)(KRSyncItem* synItem, float progress);
typedef void (^KRCloudSyncCompletedBlock)(NSArray* syncItems, NSError* error);

typedef void (^KRCloudSyncResultBlock)(BOOL succeeded, NSError* error);

typedef void (^KRCloudSyncPublishingURLBlock)(NSURL* url, BOOL succeeded, NSError* error);

typedef void (^KRResourcesCompletedBlock)(NSArray* resources, NSError* error);

typedef void (^KRServiceAvailableBlock)(BOOL available);
typedef void (^KRiCloudRemoveFileBlock)(BOOL succeeded, NSError* error);


#endif
