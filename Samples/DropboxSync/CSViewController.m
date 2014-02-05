//
//  CSViewController.m
//  DropboxSync
//
//  Created by allting on 2/5/14.
//
//

#import "CSViewController.h"
#import "KRCloudSync.h"

@interface CSViewController ()
@property (nonatomic) KRCloudSync* cloudSync;

@end

@implementation CSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStylePlain target:self action:@selector(syncWithDropbox)];
    self.navigationItem.rightBarButtonItem = anotherButton;
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
    if(!_cloudSync){
        NSString* documentPath = nil;
        if(![self createDirectoryInDocument:@"dropbox" fullPath:&documentPath])
            return;
        
        KRDropboxFactory* factory = [[KRDropboxFactory alloc] initWithDocumentsPaths:documentPath
                                                                              remote:@"/"
                                                                              filter:@[@"mnd"]
                                                                cloudServiceDelegate:self];
        
        self.cloudSync = [[KRCloudSync alloc]initWithFactory:factory];
    }
    
	[_cloudSync syncUsingBlock:^(NSArray* syncItems, NSError* error){
		if(error){
			NSLog(@"syncItems - %@", syncItems);
			NSLog(@"Failed to sync : %@", error);
		}else{
			NSLog(@"Succeeded to sync - item count:%d", [syncItems count]);
			NSLog(@"syncItems - %@", syncItems);
		}
        
        [[_cloudSync factory] setLastSyncTime:[NSDate date]];
        [[_cloudSync service] enableUpdate];
	}];
    
    [[_cloudSync service] disableUpdate];
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


#pragma mark - KRCloudServiceDelegate
-(void)itemDidChanged:(KRCloudService *)service URL:(NSURL *)url{
    NSLog(@"Cloud item changed - service:%@, url:%@", service, url);
    [self syncDropboxDocumentFiles];
}


@end
