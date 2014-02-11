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

#import <Dropbox/Dropbox.h>

NSString* dropboxLinkSucceeded = @"SucceededDropboxLink";

@interface CSViewController ()
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
    
    UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStylePlain target:self action:@selector(syncWithDropbox)];
    UIBarButtonItem *unlinkButton = [[UIBarButtonItem alloc] initWithTitle:@"Unlink" style:UIBarButtonItemStylePlain target:self action:@selector(unlinkDropbox)];
    self.navigationItem.rightBarButtonItem = syncButton;
    self.navigationItem.leftBarButtonItem = unlinkButton;
}

-(void)syncWithDropbox{
    [KRCloudSync isAvailableService:kKRDropboxService block:^(BOOL available){
        if(available){
            NSLog(@"Dropbox service is available");
            [self syncDropboxDocumentFiles];
        }else{
            NSLog(@"Can't use Dropbox service");
        }
    }];
}

-(void)syncDropboxDocumentFiles{
	[self.cloudSync syncUsingBlock:^(NSArray* syncItems, NSError* error){
		if(error){
			NSLog(@"syncItems - %@", syncItems);
			NSLog(@"Failed to sync : %@", error);
		}else{
			NSLog(@"Succeeded to sync - item count:%d", [syncItems count]);
			NSLog(@"syncItems - %@", syncItems);
		}
        
        [[_cloudSync factory] setLastSyncTime:[NSDate date]];
        [[_cloudSync service] enableUpdate];
        
        self.syncItems = syncItems;
        if([syncItems count]){
            [self.tableView reloadData];
        }else{
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"There are no items to sync" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
        }
	}];
    
    [[_cloudSync service] disableUpdate];
}

-(KRCloudSync*)cloudSync{
    if(_cloudSync){
        return _cloudSync;
    }
    
    NSString* documentPath = nil;
    if(![self createDirectoryInDocument:@"dropbox" fullPath:&documentPath])
        return nil;
    
    self.documentsPath = documentPath;
    
    KRDropboxFactory* factory = [[KRDropboxFactory alloc] initWithDocumentsPaths:documentPath
                                                                          remote:@"/"
                                                                          filter:@[@"mnd"]
                                                            cloudServiceDelegate:self];
    
    _cloudSync = [[KRCloudSync alloc]initWithFactory:factory];
    return _cloudSync;
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


-(void)unlinkDropbox{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if(!account)
        return;
    
    [account unlink];
}

#pragma mark - KRCloudServiceDelegate
-(void)itemDidChanged:(KRCloudService *)service URL:(NSURL *)url{
    NSLog(@"Cloud item changed - service:%@, url:%@", service, url);
    [self syncDropboxDocumentFiles];
}

#pragma mark - UITableView source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.syncItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    KRSyncItem* item = self.syncItems[indexPath.row];
    cell.textLabel.text = [[item localResource] displayName];
    cell.detailTextLabel.text = [[item localResource] pathByDeletingSubPath:self.documentsPath];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Row pressed!!");
}

@end
