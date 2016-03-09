//
//  BLMButtonCell.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMButtonCell.h"
#import "BLMViewUtils.h"


static CGFloat ButtonTitleTopPadding = 5.0;


@implementation BLMButtonCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    _button = [UIButton buttonWithType:UIButtonTypeCustom];

    [self.button addTarget:self action:@selector(handleActionForButton:) forControlEvents:UIControlEventTouchUpInside];

    self.button.adjustsImageWhenDisabled = NO;
    self.button.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.button];
    [self.contentView addConstraints:[BLMViewUtils constraintsForItem:self.button equalToItem:self.contentView]];

    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];

    [self updateButtonInsets]; // Must call after finishing layoutSubviews because setting the button's insets requires knowledge about the bounds of its titleLabel and imageView
}


- (void)prepareForReuse {
    [super prepareForReuse];

    self.button.imageEdgeInsets = UIEdgeInsetsZero;
    self.button.titleEdgeInsets = UIEdgeInsetsZero;
}


- (void)updateContent {
    [super updateContent];

    self.button.enabled = [self.delegate isButtonEnabledForButtonCell:self];
    self.button.alpha = (self.button.isEnabled ? 1.0 : 0.5);

    [self.button setAttributedTitle:[self.delegate attributedTitleForButtonCell:self forState:UIControlStateNormal] forState:UIControlStateNormal];
    [self.button setAttributedTitle:[self.delegate attributedTitleForButtonCell:self forState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    
    [self.button setImage:[self.delegate imageForButtonCell:self forState:UIControlStateNormal] forState:UIControlStateNormal];
    [self.button setImage:[self.delegate imageForButtonCell:self forState:UIControlStateSelected] forState:UIControlStateSelected];
    [self.button setImage:[self.delegate imageForButtonCell:self forState:UIControlStateHighlighted] forState:UIControlStateHighlighted];

    [self updateButtonInsets];
}


- (void)updateButtonInsets {
    if ((self.button.titleLabel.text.length == 0) || (self.button.currentImage == nil)) {
        return;
    }

    self.button.imageEdgeInsets = (UIEdgeInsets) {
        .top = -(CGRectGetHeight(self.button.titleLabel.bounds) + ButtonTitleTopPadding),
        .right = -CGRectGetWidth(self.button.titleLabel.bounds)
    };

    self.button.titleEdgeInsets = (UIEdgeInsets) {
        .left = -CGRectGetWidth(self.button.imageView.bounds),
        .bottom = -(CGRectGetHeight(self.button.imageView.bounds) + ButtonTitleTopPadding)
    };
}


- (void)handleActionForButton:(UIButton *)button {
    [self.delegate didFireActionForButtonCell:self];
}

@end
