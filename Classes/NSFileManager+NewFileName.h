//
//  NSFileManager+NewFileName.h
//  CloudSync
//
//  Created by allting on 2/11/14.
//  Copyright (c) 2014 allting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (NewFileName)

-(NSString*)uniqueFilePath:(NSString*)filePath;
-(NSURL*)uniqueFileURL:(NSURL*)url;

@end
