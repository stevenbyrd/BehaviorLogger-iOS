//
//  BLMButtonCell.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionViewCell.h"

@class BLMButtonCell;

@protocol BLMButtonCellDelegate <NSObject>

- (UIImage *)normalImageForButtonCell:(BLMButtonCell *)cell;
- (UIImage *)highlightedImageForButtonCell:(BLMButtonCell *)cell;
- (NSString *)titleForButtonCell:(BLMButtonCell *)cell;
- (void)didFireActionForButtonCell:(BLMButtonCell *)cell;

@end


@interface BLMButtonCell : BLMCollectionViewCell

@property (nonatomic, weak) id<BLMButtonCellDelegate> delegate;
@property (nonatomic, strong, readonly) UIButton *button;

@end
