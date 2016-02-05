//
//  BLMButtonCell.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMButtonCell.h"
#import "BLMViewUtils.h"

@implementation BLMButtonCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    _button = [UIButton buttonWithType:UIButtonTypeCustom];

    [self.button addTarget:self action:@selector(handleActionForButton:) forControlEvents:UIControlEventTouchUpInside];

    self.button.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.button];
    [self.contentView addConstraints:[BLMViewUtils constraintsForItem:self.button equalToItem:self.contentView]];

    return self;
}


- (void)updateContent {
    [super updateContent];

    self.button.enabled = [self.delegate isButtonEnabledForButtonCell:self];
    
    [self.button setTitle:[self.delegate titleForButtonCell:self] forState:UIControlStateNormal];
    [self.button setImage:[self.delegate normalImageForButtonCell:self] forState:UIControlStateNormal];
    [self.button setImage:[self.delegate highlightedImageForButtonCell:self] forState:UIControlStateHighlighted];
    [self.button setImage:[self.delegate highlightedImageForButtonCell:self] forState:UIControlStateSelected];
}


- (void)handleActionForButton:(UIButton *)button {
    [self.delegate didFireActionForButtonCell:self];
}

@end
