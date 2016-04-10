//
//  BLMTextInputCell.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMTextField.h"
#import "BLMTextInputCell.h"
#import "BLMViewUtils.h"
#import "BLMUtils.h"


#pragma mark

@interface BLMTextInputCell () <BLMTextFieldDelegate>

@end


@implementation BLMTextInputCell

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }
    
    _textField = [[BLMTextField alloc] initWithHorizontalPadding:8.0 verticalPadding:5.0];

    self.textField.delegate = self;
    self.textField.minimumFontSize = 10.0;
    self.textField.adjustsFontSizeToFitWidth = YES;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.borderStyle = UITextBorderStyleLine;
    self.textField.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeWhite];
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;

    [self.textField addTarget:self action:@selector(handleEditingChangedForTextField:) forControlEvents:UIControlEventEditingChanged];

    [self.contentView addSubview:self.textField];
    [self.contentView addConstraints:[self uniqueVerticalPositionConstraintsForSubview:self.textField]];
    [self.contentView addConstraints:[self uniqueHorizontalPositionConstraintsForSubview:self.textField]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeHeight greaterThanOrEqualToItem:self.label attribute:NSLayoutAttributeHeight constant:0.0]];

    return self;
}


- (void)handleEditingChangedForTextField:(UITextField *)textField {
    assert([BLMUtils isObject:textField equalToObject:self.textField]);
    [self.delegate didChangeInputForTextInputCell:self];
    [self updateTextFieldColor];
}


- (void)updateTextFieldColor {
    NSDictionary *attributes = nil;

    if ([self.delegate shouldAcceptInputForTextInputCell:self]) {
        self.textField.layer.borderWidth = 0.0;
        self.textField.layer.borderColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeBlack].CGColor;
    } else {
        attributes = [BLMTextInputCell errorAttributes];

        self.textField.layer.borderWidth = 1.0;
        self.textField.layer.borderColor = [BLMCollectionViewCell errorColor].CGColor;
    }

    if (![BLMUtils isDictionary:attributes equalToDictionary:self.textField.defaultTextAttributes]) {
        self.textField.defaultTextAttributes = attributes;
    }
}


- (void)updateContent {
    [super updateContent];

    self.label.text = [self.dataSource labelForTextInputCell:self];
    self.textField.text = [self.dataSource defaultInputForTextInputCell:self];
    self.textField.attributedPlaceholder = [self.dataSource attributedPlaceholderForTextInputCell:self];

    [self updateTextFieldColor];
}


+ (NSDictionary *)errorAttributes {
    static NSDictionary *errorAttributes;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        errorAttributes = @{ NSForegroundColorAttributeName:[self errorColor] };
    });

    return errorAttributes;
}

#pragma mark BLMTextFieldDelegate / UITextFieldDelegate

- (NSIndexPath *)indexPathForCollectionViewCellTextField:(BLMTextField *)textField {
    return self.indexPath;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    return NO;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.delegate shouldAcceptInputForTextInputCell:self]) {
        [self.delegate didAcceptInputForTextInputCell:self];
    } else {
        [self updateContent];
    }
}

#pragma mark BLMCollectionViewCellLayoutDelegate

- (NSArray<NSLayoutConstraint *> *)uniqueVerticalPositionConstraintsForSubview:(UIView *)subview {
    if (![BLMUtils isObject:subview equalToObject:self.textField]) {
        return [super uniqueVerticalPositionConstraintsForSubview:subview];
    }

    return @[[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeCenterY equalToItem:self.contentView constant:0.0]];
}


- (NSArray<NSLayoutConstraint *> *)uniqueHorizontalPositionConstraintsForSubview:(UIView *)subview {
    if (![BLMUtils isObject:subview equalToObject:self.textField]) {
        return [super uniqueHorizontalPositionConstraintsForSubview:subview];
    }

    return @[[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeRight equalToItem:self.contentView constant:0.0],
             [BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeLeft equalToItem:self.label attribute:NSLayoutAttributeRight constant:5.0]];
}

@end
