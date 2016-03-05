//
//  BLMTextInputCell.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionViewCell.h"


@class BLMTextInputCell;


@protocol BLMTextInputCellDelegate <NSObject>

- (NSString *)labelForTextInputCell:(BLMTextInputCell *)cell;
- (NSString *)defaultInputForTextInputCell:(BLMTextInputCell *)cell;
- (NSAttributedString *)attributedPlaceholderForTextInputCell:(BLMTextInputCell *)cell;
- (NSUInteger)minimumInputLengthForTextInputCell:(BLMTextInputCell *)cell;
- (void)didChangeInputForTextInputCell:(BLMTextInputCell *)cell;
- (BOOL)shouldAcceptInputForTextInputCell:(BLMTextInputCell *)cell;
- (void)didAcceptInputForTextInputCell:(BLMTextInputCell *)cell;

@end


@protocol BLMTextInputCellLayoutDelegate <NSObject>

- (void)configureLabelSubviewsPreferredMaxLayoutWidth;
- (NSArray<NSLayoutConstraint *> *)uniqueVerticalPositionConstraintsForSubview:(UIView *)subview;
- (NSArray<NSLayoutConstraint *> *)uniqueHorizontalPositionConstraintsForSubview:(UIView *)subview;

@end


@interface BLMTextInputCell : BLMCollectionViewCell <BLMTextInputCellLayoutDelegate>

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, weak) id<BLMTextInputCellDelegate> delegate;

- (void)updateTextAttributes;

+ (NSDictionary *)errorAttributes;

@end



