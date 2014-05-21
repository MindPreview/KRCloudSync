//
//  CSDetailViewController.h
//  Examples
//
//  Created by kkr on 5/18/14.
//
//

#import <UIKit/UIKit.h>
#import "KRSyncItem.h"

@protocol CSDetailViewControllerDelegate;

@interface CSDetailViewController : UIViewController
@property (nonatomic, weak) id<CSDetailViewControllerDelegate> delegate;

@property (nonatomic) KRSyncItem* syncItem;
@property (nonatomic) NSIndexPath* indexPath;

@end

@protocol CSDetailViewControllerDelegate <NSObject>

-(void)didChangeFileName:(CSDetailViewController*)viewController name:(NSString*)fileName;

@end