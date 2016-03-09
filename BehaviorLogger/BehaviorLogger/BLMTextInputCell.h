//
//  BLMTextInputCell.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionView.h"


@class BLMCollectionViewCellTextField;


@protocol BLMCollectionViewCellTextFieldDelegate <UITextFieldDelegate>

- (NSIndexPath *)indexPathForCollectionViewCellTextField:(BLMCollectionViewCellTextField *)textField;

@end


#pragma mark 

@interface BLMCollectionViewCellTextField : UITextField

@property (nonatomic, weak) id<BLMCollectionViewCellTextFieldDelegate> delegate;
@property (nonatomic, assign, readonly) CGFloat horizontalPadding;
@property (nonatomic, assign, readonly) CGFloat verticalPadding;

- (instancetype)initWithHorizontalPadding:(CGFloat)horizontalPadding verticalPadding:(CGFloat)verticalPadding;

@end


#pragma mark 

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

@interface BLMTextInputCell : BLMCollectionViewCell <BLMCollectionViewCellTextFieldDelegate>

@property (nonatomic, strong, readonly) BLMCollectionViewCellTextField *textField;
@property (nonatomic, weak) id<BLMTextInputCellDelegate> delegate;

- (void)updateTextFieldColor;

+ (NSDictionary *)errorAttributes;

@end



