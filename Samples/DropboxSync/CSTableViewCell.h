//
//  CSTableViewCell.h
//  Samples
//
//  Created by allting on 2/13/14.
//
//

#import <UIKit/UIKit.h>

@class KRSyncItem;

@interface CSTableViewCell : UITableViewCell

-(void)setSyncItem:(KRSyncItem*)syncItem documentsPath:(NSString*)documentsPath;
-(void)setProgressValue:(CGFloat)value;

@end
