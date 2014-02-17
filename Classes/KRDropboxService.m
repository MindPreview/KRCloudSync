//
//  KRDropboxService.m
//  CloudSync
//
//  Created by allting on 1/29/14.
//  Copyright (c) 2014 allting. All rights reserved.
//

#import "KRDropboxService.h"
#import "KRResourceProperty.h"
#import "KRSyncItem.h"
#import "KRFileService.h"

#import <Dropbox/Dropbox.h>

typedef void (^KRDropboxServiceProgressBlock)(NSURL* url, CGFloat progress);
typedef void (^KRDropboxServiceDownloadResultBlock)(BOOL succeeded, NSError* error);
typedef void (^KRDropboxServiceUploadResultBlock)(BOOL succeeded, NSError* error);
typedef void (^KRDropboxServiceResultBlock)(BOOL succeeded, NSError* error);

@interface KRDropboxService()
@property (nonatomic) KRResourceFilter* filter;
@property (nonatomic) NSArray* monitorFiles;
@end

@implementation KRDropboxService

+(BOOL)isAvailableUsingBlock:(KRServiceAvailableBlock)availableBlock{
	NSAssert(availableBlock, @"Mustn't be nil");
	if(!availableBlock)
		return NO;
	
	dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
		BOOL available = NO;
        if([[DBAccountManager sharedManager] linkedAccount])
            available = YES;
		
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		dispatch_async(mainQueue, ^{
            availableBlock(available);
		});
	});
	return YES;
}

-(id)initWithDocumentsPaths:(NSString*)path remote:(NSString *)remotePath filter:(KRResourceFilter*)filter{
	self = [super initWithDocumentsPaths:path remote:remotePath];
	if(self){
		self.filter = filter;
	}
	return self;
}

-(void)dealloc{
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];
    [fileSystem removeObserver:self];
}

-(BOOL)loadResourcesUsingBlock:(KRResourcesCompletedBlock)completed{
    if(!completed)
        return NO;
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
        DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
        if(!account)
            return;
        
        if(![DBFilesystem sharedFilesystem]){
            DBFilesystem *fileSystem = [[DBFilesystem alloc] initWithAccount:account];
            [DBFilesystem setSharedFilesystem:fileSystem];
        }

        DBError* error = nil;
        NSArray* resources = [self resourcesFromDropbox:[DBPath root] error:&error];
        
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		dispatch_async(mainQueue, ^{
            completed(resources, error);
		});
	});
    
	return YES;
}

-(NSArray*)resourcesFromDropbox:(DBPath*)path error:(DBError**)outError{
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];
    NSMutableArray* resources = [NSMutableArray arrayWithCapacity:20];
    NSArray* files = [fileSystem listFolder:path error:outError];
    if(*outError)
        return nil;
    
    for(DBFileInfo* fileInfo in files){
        if([fileInfo isFolder]){
            if([[[fileInfo path] name] hasPrefix:@"."])
                continue;
            
            NSArray* subResources = [self resourcesFromDropbox:[fileInfo path] error:outError];
            if(*outError)
                return resources;
            else
                [resources addObjectsFromArray:subResources];
            
            continue;
        }
        
        NSString* filePath = [[fileInfo path] stringValue];
        if(![_filter shouldPass:filePath])
            continue;

        NSString* escapedFilePath = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSURL* url = [NSURL URLWithString:escapedFilePath];
        NSDate* modifiedAt = [fileInfo modifiedTime];
        NSNumber* fileSize = [NSNumber numberWithLongLong:[fileInfo size]];
        
        KRResourceProperty* resource = [[KRResourceProperty alloc] initWithProperties:url createdDate:nil modifiedDate:modifiedAt size:fileSize];
        [resources addObject:resource];
    }
    
    return resources;
}

-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRCloudSyncCompletedBlock)completedBlock{
	NSAssert(completedBlock, @"Mustn't be nil");
	if(!completedBlock)
		return NO;
	
    [self syncItems:syncItems progressBlock:progressBlock completedBlock:completedBlock];
	return YES;
}

-(void)syncItems:(NSArray*)syncItems
   progressBlock:(KRCloudSyncProgressBlock)progressBlock
  completedBlock:(KRCloudSyncCompletedBlock)completedBlock{
    
    NSUInteger count = [syncItems count];
    NSUInteger __block completed = 0;
    NSError* __block lastError = nil;
    KRDropboxServiceResultBlock resultBlock = ^(BOOL succeeded, NSError* error){
        completed++;
        if(error)
            lastError = error;
        
        if(count == completed)
            completedBlock(syncItems, lastError);
    };
    
    for(KRSyncItem* item in syncItems){
        if(KRSyncItemActionNone == item.action){
            resultBlock(YES, nil);
            continue;
        }
        
        BOOL result = NO;
        NSError* error = nil;
        switch (item.action) {
            case KRSyncItemActionLocalAccept:
            case KRSyncItemActionAddToRemote:
                [self saveToCloudUsingBlocks:item
                               progressBlock:progressBlock
                                 resultBlock:resultBlock];
                break;
            case KRSyncItemActionRemoteAccept:
                [self saveToLocalUsingBlocks:item
                               progressBlock:progressBlock
                                 resultBlock:resultBlock];
                break;
            case KRSyncItemActionRemoveRemoteItem:
                result = [self removeRemoteItem:item error:&error];
                resultBlock(result, error);
                break;
            case KRSyncItemActionRemoveInLocal:
                result = [self removeInLocal:item error:&error];
                resultBlock(result, error);
                break;
            case KRSyncItemActionNone:
            default:
                break;
        }
        
        item.error = error;
    }
}

-(BOOL)saveToCloudUsingBlocks:(KRSyncItem*)item
                progressBlock:(KRCloudSyncProgressBlock)progressBlock
                  resultBlock:(KRCloudSyncResultBlock)resultBlock
{
    NSString* filePath = [[item localResource] pathByDeletingSubPath:self.localDocumentsPath];
    NSString* fileName = [filePath lastPathComponent];
    NSAssert([fileName length], @"Mustn't be nil");
    if(0 == [fileName length]){
        resultBlock(NO, [NSError errorWithDomain:@"com.mindpreview.KRCloudSync" code:5 userInfo:nil]);
        return NO;
    }
    
    NSData* data = [NSData dataWithContentsOfURL:[[item localResource] URL]];
    
    DBPath *newPath = [[DBPath root] childPath:filePath];
    
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];
    DBError* error = nil;
    BOOL ret = NO;
    DBFile *file = nil;
    
    DBFileInfo* fileInfo = [fileSystem fileInfoForPath:newPath error:&error];
    if(!fileInfo){
        error = nil;
        file = [fileSystem createFile:newPath error:&error];
    }else{
        file = [fileSystem openFile:newPath error:&error];
    }
    
    if(error){
        resultBlock(NO, error);
        return NO;
    }
    
    DBFileStatus* fileStatus = [file status];
    if(![fileStatus cached]){
        resultBlock(NO, [NSError errorWithDomain:@"com.mindpreview.KRCloudSync" code:5 userInfo:nil]);
        return NO;
    }
    
    ret = [file writeData:data error:&error];
    
    KRDropboxServiceProgressBlock dropboxProgressBlock = ^(NSURL* url, CGFloat progress){
        progressBlock(item, progress);
    };
    
    KRDropboxServiceUploadResultBlock uploadResultBlock = ^(BOOL succeeded, NSError* error){
        resultBlock(succeeded, error);
    };
    
    BOOL hasMonitor = [self monitorFileIfUploading:file
                                        newVersion:NO
                                     progressBlock:dropboxProgressBlock
                                     downloadBlock:uploadResultBlock];
    if(!hasMonitor){
        [file close];
        resultBlock(ret, error);
    }
    
    return ret;
}

-(BOOL)monitorFileIfUploading:(DBFile*)file
                   newVersion:(BOOL)newerVersion
                progressBlock:(KRDropboxServiceProgressBlock)progressBlock
                downloadBlock:(KRDropboxServiceDownloadResultBlock)uploadResultBlock{
    BOOL monitor = NO;
    DBFileStatus* status = newerVersion ? file.newerStatus : file.status;
    DBFileState state = [status state];
    if(status && DBFileStateUploading == state){
        
        NSString* path = file.info.path.stringValue;
        [self addMonitoringFile:path file:file];
        NSURL* url = [NSURL fileURLWithPath:path];
        
        [file addObserver:self block:^{
            DBFile* file = [self monitoringFileWithPath:path];
            DBFileStatus* status = newerVersion ? file.newerStatus : file.status;
            DBFileState state = [status state];
            
            if(state == DBFileStateIdle){
                DBError *error;
                if ([file update:&error]) {
                    [file removeObserver:self];
                    
                    [self removeMonitoringFile:path file:file];
                    
                    NSLog(@"%@ file uploading done", url);
                    uploadResultBlock(YES, nil);
                }else{
                    uploadResultBlock(NO, error);
                }
            }else{
                NSLog(@"%@ file progress:%f", path, status.progress);
                progressBlock(url, status.progress);
            }
        }];
        
        monitor = YES;
    }
    
    return monitor;
}

-(BOOL)saveToLocalUsingBlocks:(KRSyncItem*)item
                progressBlock:(KRCloudSyncProgressBlock)progressBlock
                  resultBlock:(KRDropboxServiceResultBlock)resultBlock{
    NSString* filePath = [[[item remoteResource] URL] path];
    filePath = [filePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSString* fileName = [filePath lastPathComponent];
    NSAssert([fileName length], @"Mustn't be nil");
    if(0 == [fileName length]){
        resultBlock(NO, [NSError errorWithDomain:@"com.mindpreview.KRCloudSync" code:5 userInfo:nil]);
        return NO;
    }

    NSURL* url = [[item localResource] URL];
    
    NSURL* parentURL = [url URLByDeletingLastPathComponent];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error;
    [fileManager createDirectoryAtURL:parentURL withIntermediateDirectories:YES attributes:nil error:&error];

    DBPath *path = [[DBPath root] childPath:filePath];
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];
    
    DBFile *file = [fileSystem openFile:path error:&error];
    if(error){
        resultBlock(NO, error);
        return NO;
    }

    KRDropboxServiceProgressBlock dropboxProgressBlock = ^(NSURL* url, CGFloat progress){
        progressBlock(item, progress);
    };
    
    KRDropboxServiceDownloadResultBlock downloadBlock = ^(BOOL succeeded, NSError* error){
        if(succeeded){
            NSError* error;
            BOOL ret = [self saveToLocal:file url:url error:&error];
            resultBlock(ret, error);
        }else{
            resultBlock(NO, error);
        }
    };
    
    BOOL hasMonitor = [self monitorFileIfNotCached:file
                                        newVersion:YES
                                     progressBlock:dropboxProgressBlock
                                     downloadBlock:downloadBlock];
    if(hasMonitor){
        return YES;
    }else{
        hasMonitor = [self monitorFileIfNotCached:file
                                       newVersion:NO
                                    progressBlock:dropboxProgressBlock
                                    downloadBlock:downloadBlock];
        if(hasMonitor)
            return YES;
    }
    
    BOOL ret = [self saveToLocal:file url:url error:&error];
    resultBlock(ret, error);
    return YES;
}

-(BOOL)monitorFileIfNotCached:(DBFile*)file
                   newVersion:(BOOL)newerVersion
                progressBlock:(KRDropboxServiceProgressBlock)progressBlock
               downloadBlock:(KRDropboxServiceDownloadResultBlock)downloadBlock{
    BOOL monitor = NO;
    DBFileStatus* status = newerVersion ? file.newerStatus : file.status;
    if(status && ![status cached]){
        
        NSString* path = file.info.path.stringValue;
        [self addMonitoringFile:path file:file];
        NSURL* url = [NSURL fileURLWithPath:path];

        [file addObserver:self block:^{
            DBFile* file = [self monitoringFileWithPath:path];
            DBFileStatus* status = newerVersion ? file.newerStatus : file.status;
            
            if(status.cached){
                DBError *error;
                if ([file update:&error]) {
                    [file removeObserver:self];

                    [self removeMonitoringFile:path file:file];
                    
                    NSLog(@"%@ file download done", url);
                    downloadBlock(YES, nil);
                }else{
                    downloadBlock(NO, error);
                }
            }else{
                NSLog(@"%@ file progress:%f", path, status.progress);
                progressBlock(url, status.progress);
            }
        }];
        
        monitor = YES;
    }
    
    return monitor;
}

-(void)addMonitoringFile:(NSString*)path file:(DBFile*)file{
    NSMutableArray* files = [NSMutableArray arrayWithArray:self.monitorFiles];
    [files addObject:@{path:file}];
    self.monitorFiles = files;
}

-(DBFile*)monitoringFileWithPath:(NSString*)path{
    for(NSDictionary* dic in self.monitorFiles){
        DBFile* file = [dic objectForKey:path];
        if(file)
            return file;
    }
    return nil;
}

-(void)removeMonitoringFile:(NSString*)path file:(DBFile*)file{
    NSMutableArray* files = [NSMutableArray arrayWithArray:self.monitorFiles];
    [files removeObject:@{path:file}];
    self.monitorFiles = files;
}

-(BOOL)saveToLocal:(DBFile*)file url:(NSURL*)localUrl error:(NSError**)outError{
    DBError* error;
    NSData *data = [file readData:&error];
    if(error){
        *outError = error;
        return NO;
    }
    
    BOOL ret = [data writeToURL:localUrl atomically:YES];
    if(!ret)
        return ret;
    
    NSDictionary *attrs = @{NSFileModificationDate:[file.info modifiedTime]};
    return [[NSFileManager defaultManager] setAttributes:attrs ofItemAtPath:[localUrl path] error:outError];
}

-(BOOL)removeRemoteItem:(KRSyncItem*)item error:(NSError**)outError{
    NSString* filePath = [[[item remoteResource] URL] path];
    filePath = [filePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSString* fileName = [url lastPathComponent];
    NSAssert([fileName length], @"Mustn't be nil");
    if(0 == [fileName length])
        return NO;
    
    DBPath *path = [[DBPath root] childPath:filePath];
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];

    NSURL* trashURL = [url URLByDeletingLastPathComponent];
    trashURL = [trashURL URLByAppendingPathComponent:@".trash" isDirectory:YES];
    DBPath* trashPath = [[DBPath root] childPath:[trashURL path]];
    DBError* error;
    BOOL ret = [fileSystem createFolder:trashPath error:&error];
    if(!ret){
        *outError = error;
        return NO;
    }
    
    NSString* uniqueFileName = [self uniqueFileNameInDirectory:fileName directory:[trashURL path]];
    NSURL* trashFullURL = [trashURL URLByAppendingPathComponent:uniqueFileName];
    DBPath* trashFilePath = [[DBPath root] childPath:[trashFullURL path]];
    ret = [fileSystem movePath:path toPath:trashFilePath error:&error];
    if(!ret){
        *outError = error;
        return NO;
    }
    
    return YES;
}

-(NSString*)uniqueFileNameInDirectory:(NSString*)fileName directory:(NSString*)directory{
    NSString* uniqueFileName = fileName;
    NSString* fileNameOnly = [fileName stringByDeletingPathExtension];
    NSString* extension = [fileName pathExtension];
    
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];
    NSString* pathString = [directory stringByAppendingPathComponent:fileName];
    DBPath* path = [[DBPath root] childPath:pathString];
    NSInteger index = 0;
    DBError* error;
    
    while (1) {
        DBFileInfo* fileInfo = [fileSystem fileInfoForPath:path error:&error];
        if(!fileInfo && DBErrorParamsNotFound == error.code){
            break;
        }else{
            uniqueFileName = [NSString stringWithFormat:@"%@ (%u)", fileNameOnly, ++index];
            uniqueFileName = [uniqueFileName stringByAppendingPathExtension:extension];
            
            pathString = [directory stringByAppendingPathComponent:uniqueFileName];
            path = [[DBPath root] childPath:pathString];
        }
    }
    
    return uniqueFileName;
}

-(BOOL)removeInLocal:(KRSyncItem*)item error:(NSError**)outError{
    NSString* filePath = [[[item localResource] URL] path];
    filePath = [filePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSString* fileName = [url lastPathComponent];
    NSAssert([fileName length], @"Mustn't be nil");
    if(0 == [fileName length])
        return NO;
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL* trashURL = [url URLByDeletingLastPathComponent];
    trashURL = [trashURL URLByAppendingPathComponent:@".trash" isDirectory:YES];
    
    [fileManager createDirectoryAtURL:trashURL withIntermediateDirectories:YES attributes:nil error:outError];
    
    trashURL = [trashURL URLByAppendingPathComponent:fileName];
    trashURL = [KRFileService uniqueFileURL:trashURL];
    
    return [fileManager moveItemAtURL:url toURL:trashURL error:outError];
}

-(void)enableUpdate{
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];
	[fileSystem addObserver:self forPathAndDescendants:[DBPath root] block:^{
        NSLog(@"%@ was changed", [[DBPath root] stringValue]);
        if([self.delegate respondsToSelector:@selector(itemDidChanged:URL:)])
            [self.delegate itemDidChanged:self URL:[NSURL URLWithString:[[DBPath root] stringValue]]];
    }];
}

-(void)disableUpdate{
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];
	[fileSystem removeObserver:self];
}

@end
