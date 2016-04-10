//
//  BLMCollectionView.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionView.h"
#import "BLMTextField.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"
#import "UIResponder+BLMAdditions.h"


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

    self.layer.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeDarkBackground].CGColor;
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

    self.label.textColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeBlack];
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

    self.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeDarkBorder alpha:0.5];

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


- (void)configureLabelSubviewsPreferredMaxLayoutWidth {
    self.label.preferredMaxLayoutWidth = CGRectGetWidth([self.label alignmentRectForFrame:self.label.frame]);
}


+ (UIColor *)errorColor {
    return [BLMViewUtils colorForHexCode:BLMColorHexCodeRed];
}

#pragma mark BLMCollectionViewCellLayoutDelegate

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

@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame collectionViewLayout:[[BLMCollectionViewLayout alloc] init]];

    if (self == nil) {
        return nil;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Event Handling

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    CGRect keyboardScreenFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardWindowFrame = [self.window convertRect:keyboardScreenFrame fromWindow:nil];
    CGRect keyboardViewFrame = [self.superview convertRect:keyboardWindowFrame fromView:nil];
    CGFloat bottomInset = (CGRectGetMaxY(self.frame) - CGRectGetMinY(keyboardViewFrame));
    NSTimeInterval duration = [BLMUtils doubleFromDictionary:notification.userInfo forKey:UIKeyboardAnimationDurationUserInfoKey defaultValue:0.0];
    UIViewAnimationCurve curve = [BLMUtils integerFromDictionary:notification.userInfo forKey:UIKeyboardAnimationCurveUserInfoKey defaultValue:UIViewAnimationCurveLinear];

    [self updateBottomInset:bottomInset afterDelay:0.0 duration:duration curve:curve completion:^(BOOL finished) {
        UIResponder *firstResponder = [UIResponder currentFirstResponder];
        assert(firstResponder != nil);

        if (![firstResponder isKindOfClass:[BLMTextField class]] || ![(BLMTextField *)firstResponder isDescendantOfView:self]) {
            return;
        }

        BLMTextField *textField = (BLMTextField *)firstResponder;
        id<BLMTextFieldDelegate> delegate = textField.delegate;
        NSIndexPath *indexPath = [delegate indexPathForCollectionViewCellTextField:textField];
        UICollectionViewLayoutAttributes *cellLayout = [(BLMCollectionViewLayout *)self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];

        [self scrollRectToVisible:cellLayout.frame animated:YES];
    }];
}


- (void)handleKeyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [BLMUtils doubleFromDictionary:notification.userInfo forKey:UIKeyboardAnimationDurationUserInfoKey defaultValue:0.0];
    UIViewAnimationCurve curve = [BLMUtils integerFromDictionary:notification.userInfo forKey:UIKeyboardAnimationCurveUserInfoKey defaultValue:UIViewAnimationCurveLinear];

    [self updateBottomInset:0.0 afterDelay:0.0 duration:duration curve:curve completion:nil];
}


- (void)updateBottomInset:(CGFloat)bottomInset afterDelay:(NSTimeInterval)delay duration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve completion:(void(^)(BOOL finished))completion {
    if (self.contentInset.bottom == bottomInset) {
        return;
    }

    UIViewAnimationOptions options = (curve << 16); // The UIViewAnimationOptions constants regarding animation curve are UIViewAnimationCurve enum values bit-shifted left by 16

    [UIView animateWithDuration:duration delay:delay options:options animations:^{
        self.contentInset = (UIEdgeInsets) {
            .top = self.contentInset.top,
            .left = self.contentInset.left,
            .bottom = bottomInset,
            .right = self.contentInset.right
        };
    } completion:completion];
}

@end


#pragma mark

@interface BLMCollectionViewLayout ()

@property (nonatomic, assign) CGSize collectionViewContentSize;
@property (nonatomic, copy) NSMutableArray<NSValue *> *sectionFrameList;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *> *attributesByIndexPathByKind;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *> *previousAttributesByIndexPathByKind;
@property (nonatomic, copy) NSMutableDictionary<NSIndexPath *, NSIndexPath *> *reloadedIndexPathByOriginalIndexPath;
@property (nonatomic, copy) NSMutableArray<NSIndexPath *> *deletedIndexPaths;
@property (nonatomic, copy) NSMutableArray<NSIndexPath *> *insertedIndexPaths;

@end


@implementation BLMCollectionViewLayout

@dynamic collectionView;

- (instancetype)init {
    self = [super init];

    if (self == nil)
        return nil;

    _collectionViewContentSize = CGSizeZero;
    _sectionFrameList = [NSMutableArray array];
    _attributesByIndexPathByKind = [NSMutableDictionary dictionary];
    _reloadedIndexPathByOriginalIndexPath = [NSMutableDictionary dictionary];
    _deletedIndexPaths = [NSMutableArray array];
    _insertedIndexPaths = [NSMutableArray array];

    return self;
}


- (void)prepareLayout {
    [super prepareLayout];

    [self.sectionFrameList removeAllObjects];

    self.previousAttributesByIndexPathByKind = self.attributesByIndexPathByKind.copy;

    for (NSString *kind in @[BLMCollectionViewKindHeader, BLMCollectionViewKindItemAreaBackground, BLMCollectionViewKindItemCell, BLMCollectionViewKindFooter]) {
        self.attributesByIndexPathByKind[kind] = [NSMutableDictionary dictionary];
    }

    CGFloat sectionWidth = CGRectGetWidth(self.collectionView.bounds);

    CGRect contentFrame = {
        .origin = CGPointZero,
        .size = {
            .width = sectionWidth,
            .height = 0.0
        }
    };

    for (NSUInteger section = 0; section < self.collectionView.numberOfSections; section += 1) {
        BLMCollectionViewSectionLayout const Layout = [self.collectionView.delegate collectionView:self.collectionView layoutForSection:section];

        CGRect sectionFrame = {
            .origin = {
                .x = CGRectGetMinX(contentFrame),
                .y = CGRectGetMaxY(contentFrame)
            },
            .size = {
                .width = sectionWidth,
                .height = 0.0
            }
        };

        if (Layout.Header.Height > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BLMCollectionViewKindHeader withIndexPath:indexPath];

            attributes.frame = CGRectPixelAlign((CGRect) {
                .origin = {
                    .x = (CGRectGetMinX(sectionFrame) + Layout.Header.Insets.left),
                    .y = (CGRectGetMaxY(sectionFrame) + Layout.Header.Insets.top) // Positioned below previous section at the bottom edge of collectionViewContentSize
                },
                .size = {
                    .width = (sectionWidth - Layout.Header.Insets.left - Layout.Header.Insets.right),
                    .height = Layout.Header.Height
                }
            });

            self.attributesByIndexPathByKind[BLMCollectionViewKindHeader][indexPath] = attributes;

            sectionFrame.size.height += (Layout.Header.Height + Layout.Header.Insets.top + Layout.Header.Insets.bottom); // Extend section frame to include the header and its insets
        }

        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];

        if (itemCount > 0) {
            NSInteger rowCount = ceilf(itemCount / (CGFloat)Layout.ItemArea.Grid.ColumnCount);
            CGFloat itemGridHeight = ((rowCount * Layout.ItemArea.Grid.RowHeight) + (Layout.ItemArea.Grid.RowSpacing * (rowCount - 1))); // Space enough for the item grid rows plus the total amount of inter-row spacing

            CGRect itemAreaFrame = {
                .origin = {
                    .x = (CGRectGetMinX(sectionFrame) + Layout.ItemArea.Insets.left),
                    .y = (CGRectGetMaxY(sectionFrame) + Layout.ItemArea.Insets.top)
                },
                .size = {
                    .width = (sectionWidth - Layout.ItemArea.Insets.left - Layout.ItemArea.Insets.right),
                    .height = (itemGridHeight + Layout.ItemArea.Grid.Insets.top + Layout.ItemArea.Grid.Insets.bottom) // Include the splace necessary to account for the item grid top/bottom insets
                }
            };

            if (Layout.ItemArea.HasBackground) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BLMCollectionViewKindItemAreaBackground withIndexPath:indexPath];

                attributes.zIndex = -1;
                attributes.frame = CGRectPixelAlign(itemAreaFrame);

                self.attributesByIndexPathByKind[BLMCollectionViewKindItemAreaBackground][indexPath] = attributes;
            }

            CGRect itemGridFrame = {
                .origin = {
                    .x = (CGRectGetMinX(itemAreaFrame) + Layout.ItemArea.Grid.Insets.left),
                    .y = (CGRectGetMinY(itemAreaFrame) + Layout.ItemArea.Grid.Insets.top)
                },
                .size = {
                    .width = (CGRectGetWidth(itemAreaFrame) - Layout.ItemArea.Grid.Insets.left - Layout.ItemArea.Grid.Insets.right),
                    .height = itemGridHeight
                }
            };

            CGFloat itemWidth = ((CGRectGetWidth(itemGridFrame) // To find the width of item cells in this section, start with the item area width...
                                  - (Layout.ItemArea.Grid.ColumnSpacing // ...then subtract the horizontal inter-column space...
                                     * (Layout.ItemArea.Grid.ColumnCount - 1))) // ...multiplied by the total number of inter-column spaces...
                                 / Layout.ItemArea.Grid.ColumnCount); // ...then divide the remaining space by the number of columns...

            for (NSInteger item = 0; item < itemCount; item += 1) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

                attributes.frame = CGRectPixelAlign((CGRect) {
                    .origin = {
                        .x = (CGRectGetMinX(itemGridFrame) // Starting at the left edge...
                              + ((itemWidth + Layout.ItemArea.Grid.ColumnSpacing) // ...then move over by the width of a column and its horizontal spacing...
                                 * (item % Layout.ItemArea.Grid.ColumnCount))), // ...multiplied by the column number for this item.
                        .y = (CGRectGetMinY(itemGridFrame)  // Starting at the top edge...
                              + ((Layout.ItemArea.Grid.RowHeight + Layout.ItemArea.Grid.RowSpacing) // ...then move down by the height of a row and its vertical spacing...
                                 * (item / Layout.ItemArea.Grid.ColumnCount))) // ...multiplied by the row number for this item.
                    },
                    .size = {
                        .width = itemWidth,
                        .height = Layout.ItemArea.Grid.RowHeight
                    }
                });

                self.attributesByIndexPathByKind[BLMCollectionViewKindItemCell][indexPath] = attributes;
            }

            sectionFrame.size.height += (CGRectGetHeight(itemAreaFrame) + Layout.ItemArea.Insets.top + Layout.ItemArea.Insets.bottom); // Extend section frame to include the item area and its insets
        }

        if (Layout.Footer.Height > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BLMCollectionViewKindFooter withIndexPath:indexPath];

            attributes.frame = CGRectPixelAlign((CGRect) {
                .origin = {
                    .x = (CGRectGetMinX(sectionFrame) + Layout.Footer.Insets.left),
                    .y = (CGRectGetMaxY(sectionFrame) + Layout.Footer.Insets.top)
                },
                .size = {
                    .width = (sectionWidth - Layout.Footer.Insets.left - Layout.Footer.Insets.right),
                    .height = Layout.Footer.Height
                }
            });

            self.attributesByIndexPathByKind[BLMCollectionViewKindFooter][indexPath] = attributes;

            sectionFrame.size.height += (Layout.Footer.Height + Layout.Footer.Insets.top + Layout.Footer.Insets.bottom); // Extend section frame to include the footer and its insets
        }

        [self.sectionFrameList addObject:[NSValue valueWithCGRect:sectionFrame]];

        contentFrame = CGRectUnion(contentFrame, sectionFrame);
    }

    self.collectionViewContentSize = contentFrame.size;
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<UICollectionViewLayoutAttributes *> *attributesForRect = [NSMutableArray array];
    BOOL scannedPastRectMaxY = NO;

    for (NSUInteger section = 0; ((section < self.collectionView.numberOfSections) && !scannedPastRectMaxY); section += 1) {
        CGRect sectionFrame = self.sectionFrameList[section].CGRectValue;

        if (CGRectGetMinY(sectionFrame) > CGRectGetMaxY(rect)) {
            scannedPastRectMaxY = YES;
            break;
        }

        if (!CGRectIntersectsRect(sectionFrame, rect)) {
            continue;
        }

        for (NSString *kind in @[BLMCollectionViewKindHeader, BLMCollectionViewKindItemAreaBackground, BLMCollectionViewKindFooter]) {
            [self.attributesByIndexPathByKind[kind] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *key, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
                if (CGRectIntersectsRect(attributes.frame, rect)) {
                    [attributesForRect addObject:attributes];
                }
            }];
        }

        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];

        for (NSInteger item = 0; item < itemCount; item += 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = self.attributesByIndexPathByKind[BLMCollectionViewKindItemCell][indexPath];

            if (CGRectGetMinY(attributes.frame) > CGRectGetMaxY(rect)) {
                scannedPastRectMaxY = YES;
                break;
            }

            if (CGRectIntersectsRect(attributes.frame, rect)) {
                [attributesForRect addObject:attributes];
            }
        }
    }

    return attributesForRect;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    assert(self.attributesByIndexPathByKind[BLMCollectionViewKindItemCell][indexPath] != nil);
    return self.attributesByIndexPathByKind[BLMCollectionViewKindItemCell][indexPath];
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    assert(self.attributesByIndexPathByKind[elementKind][indexPath] != nil);
    return self.attributesByIndexPathByKind[elementKind][indexPath];
}


- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:indexPath];

    if ([self.insertedIndexPaths containsObject:indexPath]) {
        attributes.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } else {
        for (NSIndexPath *originalIndexPath in self.reloadedIndexPathByOriginalIndexPath) {
            if ([BLMUtils isObject:self.reloadedIndexPathByOriginalIndexPath[originalIndexPath] equalToObject:indexPath]) {
                attributes = self.previousAttributesByIndexPathByKind[BLMCollectionViewKindItemCell][originalIndexPath];
                break;
            }
        }
    }

    return attributes;
}


- (nullable UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:indexPath];

    if ([self.deletedIndexPaths containsObject:indexPath]) {
        attributes.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } else {
        NSIndexPath *indexPathAfterUpdate = self.reloadedIndexPathByOriginalIndexPath[indexPath];

        if (indexPathAfterUpdate != nil) {
            attributes = [self layoutAttributesForItemAtIndexPath:indexPathAfterUpdate];
        }
    }

    return attributes;
}


- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return self.attributesByIndexPathByKind[elementKind][indexPath];
}


- (void)prepareForCollectionViewUpdates:(NSArray<UICollectionViewUpdateItem *> *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];

    for (UICollectionViewUpdateItem *update in updateItems) {
        switch (update.updateAction) {
            case UICollectionUpdateActionInsert:
                [self.insertedIndexPaths addObject:update.indexPathAfterUpdate];
                break;

            case UICollectionUpdateActionDelete:
                [self.deletedIndexPaths addObject:update.indexPathBeforeUpdate];
                break;

            case UICollectionUpdateActionReload:
                self.reloadedIndexPathByOriginalIndexPath[update.indexPathBeforeUpdate] = update.indexPathAfterUpdate;
                break;

            case UICollectionUpdateActionMove:
            case UICollectionUpdateActionNone: {
                break;
            }
        }
    }
}


- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    
    [self.reloadedIndexPathByOriginalIndexPath removeAllObjects];
    [self.deletedIndexPaths removeAllObjects];
    [self.insertedIndexPaths removeAllObjects];
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return (CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds));
}

@end

