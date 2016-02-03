//
//  BLMTextInputCell.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMTextInputCell.h"
#import "BLMPaddedTextField.h"
#import "BLMViewUtils.h"


@implementation BLMTextInputCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    _label = [[UILabel alloc] init];

    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.label.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.label];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeCenterY equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeLeft equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeRight lessThanOrEqualToItem:self.contentView attribute:NSLayoutAttributeRight constant:-30.0]];

    _textField = [[BLMPaddedTextField alloc] initWithHorizontalPadding:8.0 verticalPadding:6.0];

    self.textField.delegate = self;
    self.textField.minimumFontSize = 10.0;
    self.textField.adjustsFontSizeToFitWidth = YES;
    self.textField.borderStyle = UITextBorderStyleLine;
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.textField];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeCenterY equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeRight equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeLeft equalToItem:self.label attribute:NSLayoutAttributeRight constant:5.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeHeight greaterThanOrEqualToItem:self.label attribute:NSLayoutAttributeHeight constant:0.0]];

    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];

    self.label.preferredMaxLayoutWidth = CGRectGetWidth([self.label alignmentRectForFrame:self.label.frame]);

    [super layoutSubviews];
}


- (void)updateContent {
    [super updateContent];

    NSString *text = [self.delegate defaultInputForTextInputCell:self];
    self.textField.defaultTextAttributes = [self attributesForText:text];
    self.textField.text = text;

    NSString *placeholder = nil;
    NSDictionary *placeholderAttributes = nil;
    NSUInteger minimumInputLength = [self.delegate minimumInputLengthForTextInputCell:self];

    if (minimumInputLength != 0) {
        placeholder = [NSString stringWithFormat:@"Required (%lu or more characters)", (unsigned long)minimumInputLength];
        placeholderAttributes = @{ NSForegroundColorAttributeName:[BLMViewUtils colorWithHexValue:BLMColorHexCodeRed alpha:1.0] };
    } else {
        placeholder = @"Optional";
    }

    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:placeholderAttributes];

    self.label.text = [self.delegate labelForTextInputCell:self];
}


- (NSDictionary *)attributesForText:(NSString *)text {
    return ((text.length >= [self.delegate minimumInputLengthForTextInputCell:self]) ? nil : @{ NSForegroundColorAttributeName:[BLMViewUtils colorWithHexValue:BLMColorHexCodeRed alpha:1.0] });
}

#pragma UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    return NO;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *currentText = self.textField.text;
    NSString *updatedText = [currentText stringByReplacingCharactersInRange:range withString:string];
    self.textField.defaultTextAttributes = [self attributesForText:updatedText];

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.text.length < [self.delegate minimumInputLengthForTextInputCell:self]) {
        [self updateContent];
    } else {
        [self.delegate didAcceptInputForTextInputCell:self];
    }
}

@end
