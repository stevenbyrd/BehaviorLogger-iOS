//
//  BLMCollectionView.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionView.h"
#import "BLMViewUtils.h"
#import "BLMUtils.h"


#pragma mark Constants

BLMCollectionViewSectionLayout const BLMCollectionViewSectionLayoutNull;

NSString *const BLMCollectionViewKindHeader = @"BLMCollectionViewKindHeader";
NSString *const BLMCollectionViewKindItemAreaBackground = @"BLMCollectionViewKindItemAreaBackground";
NSString *const BLMCollectionViewKindItemCell = @"BLMCollectionViewKindItemCell";
NSString *const BLMCollectionViewKindFooter = @"BLMCollectionViewKindFooter";

CGFloat const BLMCollectionViewRoundedCornerRadius = 8.0;

static CGFloat const HeaderFontSize = 18.0;


#pragma mark

@implementation BLMItemAreaBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    self.layer.backgroundColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeDarkBackground alpha:1.0].CGColor;
    self.layer.cornerRadius = BLMCollectionViewRoundedCornerRadius;

    return self;
}

@end


#pragma mark

@implementation BLMSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    self.clipsToBounds = NO;

    _label = [[UILabel alloc] initWithFrame:CGRectZero];

    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.label.textColor = [UIColor darkTextColor];
    self.label.font = [UIFont boldSystemFontOfSize:HeaderFontSize];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.label];
    [self addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeLeft equalToItem:self constant:0.0]];
    [self addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeBaseline equalToItem:self attribute:NSLayoutAttributeBottom constant:0.0]];

    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];

    self.label.preferredMaxLayoutWidth = CGRectGetWidth([self.label alignmentRectForFrame:self.label.frame]);

    [super layoutSubviews];
}

@end


#pragma mark

@implementation BLMSectionSeparatorFooterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    self.backgroundColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeDarkBorder alpha:0.5];

    return self;
}

@end


#pragma mark

@implementation BLMCollectionViewCell

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

    [self resetIndexPathState];

    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];

    [self configureLabelSubviewsPreferredMaxLayoutWidth];

    [super layoutSubviews];
}


- (void)prepareForReuse {
    [super prepareForReuse];
    [self resetIndexPathState];
}


- (void)resetIndexPathState {
    self.section = NSNotFound;
    self.item = NSNotFound;
}


- (void)updateContent {
    assert([NSThread isMainThread]);
    assert(self.section != NSNotFound);
    assert(self.item != NSNotFound);
}

#pragma mark BLMCollectionViewCellLayoutDelegate

- (void)configureLabelSubviewsPreferredMaxLayoutWidth {
    self.label.preferredMaxLayoutWidth = CGRectGetWidth([self.label alignmentRectForFrame:self.label.frame]);
}


- (NSArray<NSLayoutConstraint *> *)uniqueVerticalPositionConstraintsForSubview:(UIView *)subview {
    assert([BLMUtils isObject:subview equalToObject:self.label]);

    return @[[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeCenterY equalToItem:self.contentView constant:0.0]];
}


- (NSArray<NSLayoutConstraint *> *)uniqueHorizontalPositionConstraintsForSubview:(UIView *)subview {
    assert([BLMUtils isObject:subview equalToObject:self.label]);

    return @[[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeLeft equalToItem:self.contentView constant:0.0]];
}

#pragma mark BLMCollectionViewCellIndexing

- (NSIndexPath *)indexPath {
    return [NSIndexPath indexPathForItem:self.item inSection:self.section];
}

@end


#pragma mark

@implementation BLMCollectionView

@end
