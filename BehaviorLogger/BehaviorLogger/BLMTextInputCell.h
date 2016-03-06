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


#pragma mark 

@protocol BLMTextInputCellLayoutDelegate <NSObject>

- (void)configureLabelSubviewsPreferredMaxLayoutWidth;
- (NSArray<NSLayoutConstraint *> *)uniqueVerticalPositionConstraintsForSubview:(UIView *)subview;
- (NSArray<NSLayoutConstraint *> *)uniqueHorizontalPositionConstraintsForSubview:(UIView *)subview;

@end


#pragma mark 

@protocol BLMTextInputCellTextFieldDelegate <BLMCollectionViewCellIndexing, UITextFieldDelegate>

@end


#pragma mark 

@interface BLMTextInputCellTextField : UITextField

@property (nonatomic, weak) id<BLMTextInputCellTextFieldDelegate> delegate;
@property (nonatomic, assign, readonly) CGFloat horizontalPadding;
@property (nonatomic, assign, readonly) CGFloat verticalPadding;

- (instancetype)initWithHorizontalPadding:(CGFloat)horizontalPadding verticalPadding:(CGFloat)verticalPadding;

@end


#pragma mark 

@interface BLMTextInputCell : BLMCollectionViewCell <BLMTextInputCellTextFieldDelegate, BLMTextInputCellLayoutDelegate>

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) BLMTextInputCellTextField *textField;
@property (nonatomic, weak) id<BLMTextInputCellDelegate> delegate;

- (void)updateTextAttributes;

+ (NSDictionary *)errorAttributes;

@end



