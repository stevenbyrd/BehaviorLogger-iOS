//
//  BLMButtonCell.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionView.h"


NS_ASSUME_NONNULL_BEGIN


@class BLMButtonCell;


@protocol BLMButtonCellDataSource <NSObject>

- (BOOL)isButtonEnabledForButtonCell:(BLMButtonCell *)cell;
- (nullable UIImage *)imageForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state;
- (NSAttributedString *)attributedTitleForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state;

@end


#pragma mark

@protocol BLMButtonCellDelegate <NSObject>

- (void)didFireActionForButtonCell:(BLMButtonCell *)cell;

@end


#pragma mark

@interface BLMButtonCell : BLMCollectionViewCell

@property (nullable, nonatomic, weak) id<BLMButtonCellDataSource> dataSource;
@property (nullable, nonatomic, weak) id<BLMButtonCellDelegate> delegate;
@property (nonatomic, strong, readonly) UIButton *button;

@end


NS_ASSUME_NONNULL_END
