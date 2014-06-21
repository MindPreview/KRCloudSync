//
//  CSViewController.m
//  DropboxSync
//
//  Created by allting on 2/5/14.
//
//

#import "CSViewController.h"
#import "KRCloudSync.h"
#import "KRDropboxFactory.h"
#import "KRSyncItem.h"
#import "KRResourceProperty.h"
#import "KRFileService.h"
#import "CSTableViewCell.h"
#import "CSDetailViewController.h"

#import <Dropbox/Dropbox.h>

NSString* dropboxLinkSucceeded = @"SucceededDropboxLink";

@interface CSViewController () <CSDetailViewControllerDelegate>
@property (nonatomic) KRCloudSync* cloudSync;
@property (nonatomic) NSArray* syncItems;
@property (nonatomic) NSString* documentsPath;

@end

@implementation CSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSyncButton) name:dropboxLinkSucceeded object:nil];
    
    [self showSyncButton];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showSyncButton{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if(!account)
        return;
    
    UIBarButtonItem *unlinkButton = [[UIBarButtonItem alloc] initWithTitle:@"Unlink" style:UIBarButtonItemStylePlain target:self action:@selector(unlinkDropbox)];
    self.navigationItem.leftBarButtonItem = unlinkButton;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFile)];
    UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStylePlain target:self action:@selector(checkAndSyncWithDropbox)];
    [self.navigationItem setRightBarButtonItems:@[syncButton, addButton]];
}

-(void)unlinkDropbox{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if(!account)
        return;
    
    [account unlink];
}

-(void)addFile{
    NSString *testFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.mnd"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    NSString* uniqueFilePath = [KRFileService uniqueFilePathInDirectory:self.documentsPath fileName:@"test.mnd"];
    NSError* error = nil;
    BOOL ret = [fileManager copyItemAtPath:testFilePath toPath:uniqueFilePath error:&error];
    
    if(ret){
        NSDictionary *attrs = @{NSFileModificationDate:[NSDate date]};
        ret = [[NSFileManager defaultManager] setAttributes:attrs ofItemAtPath:uniqueFilePath error:&error];
        if(ret){
            [self checkAndSyncWithDropbox];
        }
    }
}

-(void)checkAndSyncWithDropbox{
    [KRCloudSync isAvailableService:kKRDropboxService block:^(BOOL available){
        if(available){
            [self syncDropboxDocumentFiles:NO];
        }else{
            NSLog(@"Can't use Dropbox service");
        }
    }];
}

-(void)processSyncedItem:(NSArray*)syncItems error:(NSError*)error{
    if(error){
        NSLog(@"Failed to sync : %@", error);
        return;
    }else{
        NSLog(@"Succeeded to sync - item count:%d", [syncItems count]);
        NSLog(@"syncItems - %@", syncItems);
    }
    
    [[_cloudSync factory] setLastSyncTime:[NSDate date]];
    
    self.syncItems = [self removeDeletedItems:syncItems];
    if([syncItems count]){
        [self.tableView reloadData];
    }else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"There are no items to sync" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

-(void)syncDropboxDocumentFiles:(BOOL)syncWithRemote{
    [self.cloudSync.factory setShouldSyncWithRemote:syncWithRemote];
    
    KRCloudSyncStartBlock startBlock = ^(NSArray* syncItems){
        NSLog(@"StartBlock-%@", syncItems);
        self.syncItems = syncItems;
        [self.tableView reloadData];
    };
    
    KRCloudSyncProgressBlock progressBlock = ^(KRSyncItem* item, CGFloat progress){
        NSLog(@"ProgressBlock:%f", progress);
        CSTableViewCell* cell = [self cellForSyncItem:item];
        [cell setProgressValue:progress];
    };
    
	[self.cloudSync syncUsingBlocks:startBlock progressBlock:progressBlock completedBlock:^(NSArray* syncItems, NSError* error){
		[self processSyncedItem:syncItems error:error];
        
        [[_cloudSync service] enableUpdate];
    }];
    
    [[_cloudSync service] disableUpdate];
}

-(CSTableViewCell*)cellForSyncItem:(KRSyncItem*)item{
    
//    NSInteger row = [self.syncItems indexOfObject:item];
    NSString* path = [item localPath];
    NSInteger row = 0;
    for(KRSyncItem* syncItem in self.syncItems){
        if([path isEqualToString:[syncItem localPath]])
            break;
        row++;
    }
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    return (CSTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
}

-(KRCloudSync*)cloudSync{
    if(_cloudSync){
        return _cloudSync;
    }
    
    KRDropboxFactory* factory = [[KRDropboxFactory alloc] initWithDocumentsPaths:self.documentsPath
                                                                          remote:@"/"
                                                                          filter:@[@"mnd"]
                                                            cloudServiceDelegate:self];
    
    _cloudSync = [[KRCloudSync alloc]initWithFactory:factory];
    return _cloudSync;
}

-(NSString*)documentsPath{
    if(_documentsPath)
        return _documentsPath;
    
    NSString* documentsPath = nil;
    if(![self createDirectoryInDocument:@"dropbox" fullPath:&documentsPath])
        return nil;
    _documentsPath = documentsPath;
    return documentsPath;
}

-(BOOL)createDirectoryInDocument:(NSString*)path fullPath:(NSString**)fullpath{
    NSString* documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	*fullpath = [documentPath stringByAppendingPathComponent:path];
	
	return [self createDirectory:*fullpath];
}

-(BOOL)createDirectory:(NSString*)path{
	NSError* error = nil;
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path
											 withIntermediateDirectories:YES
															  attributes:nil
																   error:&error];
	if(!success || error)
		return NO;
	return YES;
}

-(NSArray*)removeDeletedItems:(NSArray*)syncItems{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:[syncItems count]];
    
    for(KRSyncItem* item in syncItems){
        if(KRSyncItemActionRemoveInLocal != item.action)
            [array addObject:item];
    }
    return array;
}

#pragma mark - KRCloudServiceDelegate
-(void)itemDidChanged:(KRCloudService *)service URL:(NSURL *)url{
    NSLog(@"Cloud item changed - service:%@, url:%@", service, url);
    [self syncDropboxDocumentFiles:YES];
}

#pragma mark - UITableView source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.syncItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    CSTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    KRSyncItem* item = self.syncItems[indexPath.row];
    [cell setSyncItem:item documentsPath:self.documentsPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        KRSyncItem* item = [self.syncItems objectAtIndex:indexPath.row];
        NSURL* url = [[item localResource] URL];
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSError* error;
        BOOL ret = [fileManager removeItemAtURL:url error:&error];
        if(ret){
            [self syncDropboxDocumentFiles:NO];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Row pressed!!");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"masterToDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        id object = [self.syncItems objectAtIndex:[indexPath row]];
        [[segue destinationViewController] setDelegate:self];
        [(CSDetailViewController*)[segue destinationViewController] setSyncItem:object];
        [(CSDetailViewController*)[segue destinationViewController] setIndexPath:indexPath];
    }
}

/// MARK: CSDetailViewController delegate
- (void)didChangeFileName:(CSDetailViewController*)viewController name:(NSString *)fileName{
    KRSyncItem* syncItem = viewController.syncItem;
    NSString* srcPath = [[[syncItem localResource] URL] path];
    NSString* destPath = [self.documentsPath stringByAppendingPathComponent:fileName];
    destPath = [KRFileService uniqueFilePath:destPath];
    
    NSError* error;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if(![fileManager moveItemAtPath:srcPath toPath:destPath error:&error]){
        NSLog(@"Can't rename file - src:%@, dest:%@", srcPath, destPath);
        return;
    }

    NSString* filePath = [syncItem remotePath];
    [[self.cloudSync service] renameFileUsingBlock:filePath newFileName:[destPath lastPathComponent] completedBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"renameFile - ret:%@, error:%@", succeeded?@"YES":@"NO", error);
    }];
}

@end
