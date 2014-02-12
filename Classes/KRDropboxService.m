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

        DBError* error = nil;
        DBFile* file = [fileSystem openFile:[fileInfo path] error:&error];
        if(!file || error)
            continue;
        
        BOOL hasMonitor = [self monitorFileIfNotCached:file version:YES];
        if(!hasMonitor){
            hasMonitor = [self monitorFileIfNotCached:file version:NO];
            if(!hasMonitor)
                [file close];
        }
        
        NSString* escapedFilePath = [filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSURL* url = [NSURL URLWithString:escapedFilePath];
        NSDate* modifiedAt = [fileInfo modifiedTime];
        NSNumber* fileSize = [NSNumber numberWithLongLong:[fileInfo size]];
        
        KRResourceProperty* resource = [[KRResourceProperty alloc] initWithProperties:url createdDate:nil modifiedDate:modifiedAt size:fileSize];
        [resources addObject:resource];
    }
    
    return resources;
}

-(BOOL)monitorFileIfNotCached:(DBFile*)file version:(BOOL)newerVersion{
    BOOL monitor = NO;
    DBFileStatus* status = newerVersion ? file.newerStatus : file.status;
    if(status && ![status cached]){
        
        NSString* path = file.info.path.stringValue;
        [self addMonitoringFile:path file:file];
        
        [file addObserver:self block:^{
            DBFile* file = [self monitoringFileWithPath:path];
            DBFileStatus* status = newerVersion ? file.newerStatus : file.status;
            
            if(status.cached){
                DBError *error;
                if ([file update:&error]) {
                    [file removeObserver:self];
                    
                    NSURL* url = [NSURL fileURLWithPath:path];
                    
                    if([file isOpen]){
                        [file close];
                    }
                    [self removeMonitoringFile:path file:file];
                    
                    NSLog(@"%@ file download done", url);
                    [self.delegate itemDidChanged:self URL:url];
                }
            }else{
                NSLog(@"%@ file progress:%f", path, status.progress);
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


-(BOOL)syncUsingBlock:(NSArray*)syncItems
		progressBlock:(KRCloudSyncProgressBlock)progressBlock
	   completedBlock:(KRSynchronizerCompletedBlock)completed{
	NSAssert(completed, @"Mustn't be nil");
	if(!completed)
		return NO;
	
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
        NSError* lastError = nil;
		
		[self syncItems:syncItems error:&lastError];
        
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		dispatch_async(mainQueue, ^{
            completed(syncItems, lastError);
		});
	});
    
	return YES;
}

-(void)syncItems:(NSArray*)syncItems error:(NSError**)outError{
    for(KRSyncItem* item in syncItems){
        if(KRSyncItemActionNone == item.action)
            continue;
        
        NSError* error = nil;
        switch (item.action) {
            case KRSyncItemActionLocalAccept:
            case KRSyncItemActionAddToRemote:
                [self saveToCloud:item error:&error];
                break;
            case KRSyncItemActionRemoteAccept:
                [self saveToLocal:item error:&error];
                break;
            case KRSyncItemActionRemoveInLocal:
                [self removeInLocal:item error:&error];
                break;
            case KRSyncItemActionNone:
            default:
                break;
        }
        
        item.error = error;
        if(error){
            *outError = error;
        }
    }
}

-(BOOL)saveToCloud:(KRSyncItem*)item error:(NSError**)outError{
    NSString* filePath = [[item localResource] pathByDeletingSubPath:self.localDocumentsPath];
    NSString* fileName = [filePath lastPathComponent];
    NSAssert([fileName length], @"Mustn't be nil");
    if(0 == [fileName length])
        return NO;
    
    NSData* data = [NSData dataWithContentsOfURL:[[item localResource] URL]];
    
    DBPath *newPath = [[DBPath root] childPath:filePath];
    
    DBFilesystem* fileSystem = [DBFilesystem sharedFilesystem];
    DBError* error = nil;
    BOOL ret = NO;
    DBFile *file = nil;
    
    DBFileInfo* fileInfo = [fileSystem fileInfoForPath:newPath error:&error];
    if(!fileInfo){
        file = [fileSystem createFile:newPath error:&error];
    }else{
        file = [fileSystem openFile:newPath error:&error];
    }
    
    if(error){
        *outError = error;
        return NO;
    }
    
    DBFileStatus* fileStatus = [file status];
    if(![fileStatus cached]){
        return NO;
    }
    
    ret = [file writeData:data error:&error];
    [file close];
    *outError = error;
    return ret;
}

-(BOOL)saveToLocal:(KRSyncItem*)item error:(NSError**)outError{
    NSString* filePath = [[[item remoteResource] URL] path];
    filePath = [filePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSString* fileName = [filePath lastPathComponent];
    NSAssert([fileName length], @"Mustn't be nil");
    if(0 == [fileName length])
        return NO;

    DBPath *path = [[DBPath root] childPath:filePath];
    
    DBError* error = nil;
    DBFile *file = [[DBFilesystem sharedFilesystem] openFile:path error:&error];
    if(error){
        *outError = error;
        return NO;
    }

    DBFileStatus* fileState = [file status];
    if(![fileState cached]){
        NSLog(@"file was not cached:%@", [path stringValue]);
    }
    
    
    NSData *data = [file readData:&error];
    if(error){
        *outError = error;
        return NO;
    }
    
    NSURL* url = [[item localResource] URL];

    NSURL* parentURL = [url URLByDeletingLastPathComponent];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtURL:parentURL withIntermediateDirectories:YES attributes:nil error:outError];
    
    BOOL ret = [data writeToURL:url atomically:YES];
    if(!ret)
        return ret;
    
    DBFileInfo* fileInfo = [file info];
    NSDictionary *attrs = @{NSFileModificationDate:[fileInfo modifiedTime]};
    return [[NSFileManager defaultManager] setAttributes:attrs ofItemAtPath:[url path] error:outError];
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
