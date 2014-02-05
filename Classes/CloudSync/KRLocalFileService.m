//
//  KRLocalFileService.m
//  CloudSync
//
//  Created by allting on 12. 10. 21..
//  Copyright (c) 2012년 allting. All rights reserved.
//

#import "KRLocalFileService.h"
#import "KRResourceProperty.h"

#define DUPLICATE_FILE_FORMAT_STRING_MIN_LENGTH	4
static NSString* NEW_FILENAME_FORMAT_STRING = @" (%d)";

NSString* uniqueFileFullPathInDirectory(NSString* dir, NSString* fileName){
	NSString* fileExtension = [fileName pathExtension];
	NSString* fileNameOnly = [fileName stringByDeletingPathExtension];
	
	FileExistBlock block = ^(NSString* path){
		return isExistFile(path);
	};
	
	NSString* newFileName = createNewFileName(dir, fileNameOnly, fileExtension, block);
	return [dir stringByAppendingPathComponent:newFileName];
}

BOOL isExistFile(NSString* filePath){
	if(!filePath || 0 == [filePath length])
		return NO;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [fileManager fileExistsAtPath:filePath];
}

NSString* createNewFileName(NSString* directory, NSString* fileName, NSString* fileExtension, FileExistBlock block)
{
	assert(block);
	if(!block)
		return nil;
	
	NSString* filePath = [directory stringByAppendingPathComponent:fileName];
	if(0<[fileExtension length])
		filePath = [filePath stringByAppendingPathExtension:fileExtension];
	
	// An input filename is a unique filename.
	if(!(block)(filePath))
		return [fileName stringByAppendingPathExtension:fileExtension];
	
	NSString* fileNameOnly = fileName;
	NSUInteger length = [fileName length];
	
	if(DUPLICATE_FILE_FORMAT_STRING_MIN_LENGTH<length){
		fileNameOnly = extractFileNameIfHasDuplicateFormatString(fileNameOnly);
	}
	
	NSUInteger i=0;
	NSString* newFileName = fileNameOnly;
	while((block)(filePath)){
		++i;
		newFileName = [fileNameOnly stringByAppendingFormat:NEW_FILENAME_FORMAT_STRING, i];
		if(0<[fileExtension length])
			newFileName = [newFileName stringByAppendingPathExtension:fileExtension];
		
		filePath = [directory stringByAppendingPathComponent:newFileName];
	}
	return newFileName;
}

NSString* extractFileNameIfHasDuplicateFormatString(NSString* fileName){
	NSRange range = [fileName rangeOfString:@" " options:NSBackwardsSearch];
	if(range.location==NSNotFound)
		return fileName;
	
	NSString* fileNameOnly = [fileName substringWithRange:NSMakeRange(0, range.location)];
	NSString* formattedString = [fileName substringFromIndex:range.location];
	if([formattedString length]<DUPLICATE_FILE_FORMAT_STRING_MIN_LENGTH)
		return fileName;
	
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@" \\(\\d+\\)"
																		   options:NSRegularExpressionCaseInsensitive
																			 error:nil];
	NSArray* matches = [regex matchesInString:formattedString
									  options:NSMatchingReportCompletion
										range:NSMakeRange(0, [formattedString length])];
	if(0 == [matches count])
		return fileName;
	
	return fileNameOnly;
}


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
