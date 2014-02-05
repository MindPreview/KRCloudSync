//
//  KRLocalFileService.h
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRFileService.h"
#import "KRResourceFilter.h"

typedef BOOL(^FileExistBlock)(NSString*);

NSString* uniqueFileFullPathInDirectory(NSString* dir, NSString* fileName);
BOOL isExistFile(NSString* filePath);
NSString* createNewFileName(NSString* directory, NSString* fileName, NSString* fileExtension, FileExistBlock block);
NSString* extractFileNameIfHasDuplicateFormatString(NSString* fileName);


@interface KRLocalFileService : KRFileService

-(NSArray*)load;

@end
