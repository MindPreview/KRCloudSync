//
//  NSFileManager+NewFileName.m
//  CloudSync
//
//  Created by allting on 2/11/14.
//  Copyright (c) 2014 allting. All rights reserved.
//

#import "NSFileManager+NewFileName.h"

typedef BOOL(^NewFileNameFileExistBlock)(NSString*);

@implementation NSFileManager (NewFileName)

#define DUPLICATE_FILE_FORMAT_STRING_MIN_LENGTH	4
static NSString* NEW_FILENAME_FORMAT_STRING = @" (%d)";

static NSString* uniqueFileFullPathInDirectory(NSString* dir, NSString* fileName){
	NSString* fileExtension = [fileName pathExtension];
	NSString* fileNameOnly = [fileName stringByDeletingPathExtension];
	
	NewFileNameFileExistBlock block = ^(NSString* path){
		return isExistFile(path);
	};
	
	NSString* newFileName = createNewFileName(dir, fileNameOnly, fileExtension, block);
	return [dir stringByAppendingPathComponent:newFileName];
}

static BOOL isExistFile(NSString* filePath){
	if(!filePath || 0 == [filePath length])
		return NO;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [fileManager fileExistsAtPath:filePath];
}

static NSString* createNewFileName(NSString* directory, NSString* fileName, NSString* fileExtension, NewFileNameFileExistBlock block)
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

static NSString* extractFileNameIfHasDuplicateFormatString(NSString* fileName){
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

-(NSString*)uniqueFilePath:(NSString*)filePath{
    NSString* dir = [filePath stringByDeletingLastPathComponent];
    NSString* file = [filePath lastPathComponent];
    
    return uniqueFileFullPathInDirectory(dir, file);
}

-(NSURL*)uniqueFileURL:(NSURL*)url{
    NSString* path = [self uniqueFilePath:[url path]];
    return [NSURL fileURLWithPath:path];
}

@end
