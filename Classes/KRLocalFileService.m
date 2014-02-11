//
//  KRLocalFileService.m
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRLocalFileService.h"
#import "KRResourceProperty.h"

@implementation KRLocalFileService

-(NSArray*)load{
	NSString* documentPath = self.localDocumentsPath;
    return [self loadWithDirectory:documentPath];
}

-(NSArray*)loadWithDirectory:(NSString*)dir{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	NSError* error = nil;
	NSArray* files = [fileManager contentsOfDirectoryAtPath:dir error:&error];
	if([error code]!=0)
		return nil;
	
	NSMutableArray* resources = [NSMutableArray arrayWithCapacity:[files count]];
	for(NSString* file in files){
        if([file hasPrefix:@"."])
            continue;
        
		NSString* path = [dir stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        [fileManager fileExistsAtPath:path isDirectory:&isDir];
        if(isDir){
            NSArray* subResources = [self loadWithDirectory:path];
            [resources addObjectsFromArray:subResources];
            continue;
        }
        
		if(![super.filter shouldPass:path])
			continue;
		
		NSError* error = nil;
		NSDictionary* attributes = [fileManager attributesOfItemAtPath:path error:&error];
		if([error code])
			continue;
		
		NSURL* url = [NSURL fileURLWithPath:path];
		NSDate* createdDate = [attributes objectForKey:NSFileCreationDate];
		NSDate* modifiedDate = [attributes objectForKey:NSFileModificationDate];
		NSNumber* size = [attributes objectForKey:NSFileSize];
		
		KRResourceProperty* resource = [[KRResourceProperty alloc]initWithProperties:url createdDate:createdDate modifiedDate:modifiedDate size:size];
		[resources addObject:resource];
	}
	
	return resources;
}

@end
