//
//  BLMTextInputCell.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionView.h"


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

@class BLMTextField;


@interface BLMTextInputCell : BLMCollectionViewCell

@property (nonatomic, strong, readonly) BLMTextField *textField;
@property (nonatomic, weak) id<BLMTextInputCellDelegate> delegate;

- (void)updateTextFieldColor;

+ (NSDictionary *)errorAttributes;

@end
