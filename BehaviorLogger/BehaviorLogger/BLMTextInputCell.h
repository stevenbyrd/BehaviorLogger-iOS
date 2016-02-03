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
- (NSUInteger)minimumInputLengthForTextInputCell:(BLMTextInputCell *)cell;
- (void)didAcceptInputForTextInputCell:(BLMTextInputCell *)cell;

@end


@interface BLMTextInputCell : BLMCollectionViewCell <UITextFieldDelegate>

@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, weak) id<BLMTextInputCellDelegate> delegate;

@end
