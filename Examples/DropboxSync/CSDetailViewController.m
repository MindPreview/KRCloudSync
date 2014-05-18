//
//  CSDetailViewController.m
//  Examples
//
//  Created by kkr on 5/18/14.
//
//

#import "CSDetailViewController.h"
#import "KRResourceProperty.h"

@interface CSDetailViewController ()
@property (nonatomic) IBOutlet UITextField* textField;
@end

@implementation CSDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSAssert(_syncItem, @"Must not be nil");
    self.textField.text = [self fileName];
}

- (NSString*)fileName{
    return [[[[self.syncItem localResource] URL] path] lastPathComponent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    if([[self fileName] isEqualToString:self.textField.text])
        return;
        
    if([self.delegate respondsToSelector:@selector(didChangeFileName:name:)])
        [self.delegate didChangeFileName:self name:self.textField.text];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
