//
//  CSTableViewCell.m
//  Samples
//
//  Created by allting on 2/13/14.
//
//

#import "CSTableViewCell.h"
#import "KRSyncItem.h"
#import "KRResourceProperty.h"

@interface CSTableViewCell()
@property (nonatomic) IBOutlet UILabel* titleLabel;
@property (nonatomic) IBOutlet UILabel* detailLabel;
@property (nonatomic) IBOutlet UIProgressView* progressView;
@end

@implementation CSTableViewCell

-(void)setSyncItem:(KRSyncItem*)syncItem documentsPath:(NSString*)documentsPath{
    self.titleLabel.text = [[syncItem localResource] displayName];
    NSString* detailText = [NSString stringWithFormat:@"%@ (%@)", [[syncItem localResource] pathByDeletingSubPath:documentsPath], [[syncItem localResource] size]];
    self.detailLabel.text = detailText;
}

-(void)setProgressValue:(CGFloat)value{
    self.progressView.progress = value;
}

@end
