//
//  BLMTextInputCell.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/2/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMTextInputCell.h"
#import "BLMViewUtils.h"
#import "BLMUtils.h"


@implementation BLMTextInputCellTextField

@dynamic delegate;

- (instancetype)initWithHorizontalPadding:(CGFloat)horizontalPadding verticalPadding:(CGFloat)verticalPadding {
    self = [super initWithFrame:CGRectZero];

    if (self == nil) {
        return nil;
    }

    _horizontalPadding = horizontalPadding;
    _verticalPadding = verticalPadding;

    return self;
}


- (CGRect)textRectForBounds:(CGRect)bounds { // placeholder position
    return CGRectInset(bounds, (self.horizontalPadding - 1.0), self.verticalPadding); // -1.0 pixel workaround for NSAttributedString size bug
}


- (CGRect)editingRectForBounds:(CGRect)bounds { // text position
    return CGRectInset(bounds, (self.horizontalPadding - 1.0), self.verticalPadding); // -1.0 pixel workaround for NSAttributedString size bug
}

@end


#pragma mark

@implementation BLMTextInputCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    _label = [[UILabel alloc] initWithFrame:CGRectZero];

    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.label.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.label];
    [self.contentView addConstraints:[self uniqueVerticalPositionConstraintsForSubview:self.label]];
    [self.contentView addConstraints:[self uniqueHorizontalPositionConstraintsForSubview:self.label]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeRight lessThanOrEqualToItem:self.contentView attribute:NSLayoutAttributeRight constant:-30.0]];

    _textField = [[BLMTextInputCellTextField alloc] initWithHorizontalPadding:8.0 verticalPadding:6.0];

    self.textField.delegate = self;
    self.textField.minimumFontSize = 10.0;
    self.textField.adjustsFontSizeToFitWidth = YES;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.borderStyle = UITextBorderStyleLine;
    self.textField.backgroundColor = [UIColor whiteColor];
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


- (void)layoutSubviews {
    [super layoutSubviews];

    [self configureLabelSubviewsPreferredMaxLayoutWidth];

    [super layoutSubviews];
}


- (void)handleEditingChangedForTextField:(UITextField *)textField {
    assert([BLMUtils isObject:textField equalToObject:self.textField]);
    [self.delegate didChangeInputForTextInputCell:self];
    [self updateTextAttributes];
}


- (void)updateTextAttributes {
    NSDictionary *attributes = ([self.delegate shouldAcceptInputForTextInputCell:self] ? nil : [BLMTextInputCell errorAttributes]);

    if (![BLMUtils isDictionary:attributes equalToDictionary:self.textField.defaultTextAttributes]) {
        self.textField.defaultTextAttributes = attributes;
    }
}


- (void)updateContent {
    [super updateContent];

    self.label.text = [self.delegate labelForTextInputCell:self];
    self.textField.text = [self.delegate defaultInputForTextInputCell:self];
    self.textField.attributedPlaceholder = [self.delegate attributedPlaceholderForTextInputCell:self];

    [self updateTextAttributes];
}


+ (NSDictionary *)errorAttributes {
    static NSDictionary *errorAttributes;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        errorAttributes = @{ NSForegroundColorAttributeName:[BLMViewUtils colorWithHexValue:BLMColorHexCodeRed alpha:1.0] };
    });

    return errorAttributes;
}

#pragma mark UITextFieldDelegate

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

#pragma mark BLMTextInputCellLayoutDelegate

- (void)configureLabelSubviewsPreferredMaxLayoutWidth {
    self.label.preferredMaxLayoutWidth = CGRectGetWidth([self.label alignmentRectForFrame:self.label.frame]);
}


- (NSArray<NSLayoutConstraint *> *)uniqueVerticalPositionConstraintsForSubview:(UIView *)subview {
    NSMutableArray *constraints = [NSMutableArray array];

    if ([BLMUtils isObject:subview equalToObject:self.label]) {
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeCenterY equalToItem:self.contentView constant:0.0]];
    } else if ([BLMUtils isObject:subview equalToObject:self.textField]) {
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeCenterY equalToItem:self.contentView constant:0.0]];
    }

    return constraints;
}


- (NSArray<NSLayoutConstraint *> *)uniqueHorizontalPositionConstraintsForSubview:(UIView *)subview {
    NSMutableArray *constraints = [NSMutableArray array];

    if ([BLMUtils isObject:subview equalToObject:self.label]) {
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeLeft equalToItem:self.contentView constant:0.0]];
    } else if ([BLMUtils isObject:subview equalToObject:self.textField]) {
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeRight equalToItem:self.contentView constant:0.0]];
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeLeft equalToItem:self.label attribute:NSLayoutAttributeRight constant:5.0]];
    }

    return constraints;
}

@end
