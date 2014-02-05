//
//  KRResourceProperty.h
//  CloudSync
//
//  Created by allting on 12. 10. 11..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KRSyncItem.h"

@interface KRResourceProperty : NSObject
@property (nonatomic) NSURL* URL;
@property (nonatomic) NSDate* createdDate;
@property (nonatomic) NSDate* modifiedDate;
@property (nonatomic) NSNumber* size;
@property (nonatomic) NSString* displayName;
@property (nonatomic) id<NSObject> userData;

-(id)initWithProperties:(NSURL*)url
			createdDate:(NSDate*)createDate
		   modifiedDate:(NSDate*)modifiedDate
				   size:(NSNumber*)size;

-(id)initWithMetadataItem:(NSMetadataItem*)item;

-(KRSyncItemAction)compare:(KRResourceProperty*)anotherResource;
-(NSString*)pathByDeletingSubPath:(NSString*)basePath;

-(NSString*)description;

@end
