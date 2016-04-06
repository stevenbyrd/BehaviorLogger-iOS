//
//  BLMButtonCell.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionView.h"


@class BLMButtonCell;


@protocol BLMButtonCellDataSource <NSObject>

- (BOOL)isButtonEnabledForButtonCell:(BLMButtonCell *)cell;
- (UIImage *)imageForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state;
- (NSAttributedString *)attributedTitleForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state;

@end


#pragma mark

@protocol BLMButtonCellDelegate <NSObject>

- (void)didFireActionForButtonCell:(BLMButtonCell *)cell;

@end


#pragma mark

@interface BLMButtonCell : BLMCollectionViewCell

@property (nonatomic, weak) id<BLMButtonCellDataSource> dataSource;
@property (nonatomic, weak) id<BLMButtonCellDelegate> delegate;
@property (nonatomic, strong, readonly) UIButton *button;

@end
