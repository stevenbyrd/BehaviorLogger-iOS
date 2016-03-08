//
//  BLMProjectDetailCollectionViewLayout.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCollectionView.h"
#import "BLMProjectDetailCollectionViewLayout.h"
#import "BLMUtils.h"


@interface BLMProjectDetailCollectionViewLayout ()

@property (nonatomic, weak) id<BLMProjectDetailCollectionViewLayoutDelegate> layoutDelegate;
@property (nonatomic, assign) CGSize collectionViewContentSize;
@property (nonatomic, copy) NSMutableArray<NSValue *> *sectionFrameList;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *> *attributesByIndexPathByKind;
@property (nonatomic, copy) NSDictionary<NSString *, NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *> *previousAttributesByIndexPathByKind;
@property (nonatomic, copy) NSMutableDictionary<NSIndexPath *, NSIndexPath *> *reloadedIndexPathByOriginalIndexPath;
@property (nonatomic, copy) NSMutableArray<NSIndexPath *> *deletedIndexPaths;
@property (nonatomic, copy) NSMutableArray<NSIndexPath *> *insertedIndexPaths;

@end


@implementation BLMProjectDetailCollectionViewLayout

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

    for (BLMProjectDetailSection section = 0; section < BLMProjectDetailSectionCount; section += 1) {
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

        BLMCollectionViewSectionLayout const Layout = [self.layoutDelegate projectDetailCollectionViewLayout:self layoutForSection:section];

        if (Layout.Header.Height > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BLMCollectionViewKindHeader withIndexPath:indexPath];

            attributes.frame = (CGRect) {
                .origin = {
                    .x = (CGRectGetMinX(sectionFrame) + Layout.Header.Insets.left),
                    .y = (CGRectGetMaxY(sectionFrame) + Layout.Header.Insets.top) // Positioned below previous section at the bottom edge of collectionViewContentSize
                },
                .size = {
                    .width = (sectionWidth - Layout.Header.Insets.left - Layout.Header.Insets.right),
                    .height = Layout.Header.Height
                }
            };

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

                attributes.frame = itemAreaFrame;

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

            CGSize itemSize = {
                .width = ((((CGRectGetWidth(itemGridFrame) // To find the width of item cells in this section, start with the item area width...
                             - (Layout.ItemArea.Grid.ColumnSpacing // ...then subtract the horizontal inter-column space...
                                * (Layout.ItemArea.Grid.ColumnCount - 1))) // ...multiplied by the total number of inter-column spaces...
                            / Layout.ItemArea.Grid.ColumnCount) // ...then divide the remaining space by the number of columns...
                           + 0.5) / 1), // ...and finally round to the nearest whole number so that item frames are pixel-aligned,
                .height = Layout.ItemArea.Grid.RowHeight
            };

            for (NSInteger item = 0; item < itemCount; item += 1) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

                attributes.frame = (CGRect) {
                    .origin = {
                        .x = (CGRectGetMinX(itemGridFrame) + ((itemSize.width + Layout.ItemArea.Grid.ColumnSpacing) * [self columnForItem:item section:section])), // Move from left edge to appropriate column
                        .y = (CGRectGetMinY(itemGridFrame) + ((Layout.ItemArea.Grid.RowHeight + Layout.ItemArea.Grid.RowSpacing) * [self rowForItem:item section:section])) // Move from top edge to appropriate row
                    },
                    .size = itemSize
                };
                
                attributes.zIndex = 1;
                
                self.attributesByIndexPathByKind[BLMCollectionViewKindItemCell][indexPath] = attributes;
            }

            sectionFrame.size.height += (CGRectGetHeight(itemAreaFrame) + Layout.ItemArea.Insets.top + Layout.ItemArea.Insets.bottom); // Extend section frame to include the item area and its insets
        }

        if (Layout.Footer.Height > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:BLMCollectionViewKindFooter withIndexPath:indexPath];

            attributes.frame = (CGRect) {
                .origin = {
                    .x = (CGRectGetMinX(sectionFrame) + Layout.Footer.Insets.left),
                    .y = (CGRectGetMaxY(sectionFrame) + Layout.Footer.Insets.top)
                },
                .size = {
                    .width = (sectionWidth - Layout.Footer.Insets.left - Layout.Footer.Insets.right),
                    .height = Layout.Footer.Height
                }
            };

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

    for (BLMProjectDetailSection section = 0; ((section < BLMProjectDetailSectionCount) && !scannedPastRectMaxY); section += 1) {
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
    UICollectionViewLayoutAttributes *initialAttributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:indexPath];

    switch ((BLMProjectDetailSection)indexPath.section) {
        case BLMProjectDetailSectionBasicInfo:
        case BLMProjectDetailSectionSessionProperties:
        case BLMProjectDetailSectionActionButtons:
            break;

        case BLMProjectDetailSectionBehaviors: {
            if ([self.insertedIndexPaths containsObject:indexPath]) {
                initialAttributes.transform = CGAffineTransformMakeScale(0.01, 0.01);
                break;
            }

            for (NSIndexPath *originalIndexPath in self.reloadedIndexPathByOriginalIndexPath) {
                if ([BLMUtils isObject:self.reloadedIndexPathByOriginalIndexPath[originalIndexPath] equalToObject:indexPath]) {
                    initialAttributes = [self.previousAttributesByIndexPathByKind[BLMCollectionViewKindItemCell][originalIndexPath] copy];
                    break;
                }
            }
            break;
        }

        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return initialAttributes;
}


- (nullable UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *finalAttributes = [super finalLayoutAttributesForDisappearingItemAtIndexPath:indexPath];

    switch ((BLMProjectDetailSection)indexPath.section) {
        case BLMProjectDetailSectionBasicInfo:
        case BLMProjectDetailSectionSessionProperties:
        case BLMProjectDetailSectionActionButtons:
            break;

        case BLMProjectDetailSectionBehaviors: {
            if ([self.deletedIndexPaths containsObject:indexPath]) {
                finalAttributes.transform = CGAffineTransformMakeScale(0.01, 0.01);
                break;
            }

            NSIndexPath *indexPathAfterUpdate = self.reloadedIndexPathByOriginalIndexPath[indexPath];

            if (indexPathAfterUpdate != nil) {
                finalAttributes = [self layoutAttributesForItemAtIndexPath:indexPathAfterUpdate];
            }
            break;
        }

        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return finalAttributes;
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


- (id<BLMProjectDetailCollectionViewLayoutDelegate>)layoutDelegate {
    return (id<BLMProjectDetailCollectionViewLayoutDelegate>)self.collectionView.delegate;
}

#pragma mark Layout Utilities

- (NSUInteger)columnForItem:(NSUInteger)item section:(BLMProjectDetailSection)section {
    BLMCollectionViewSectionLayout layout = [self.layoutDelegate projectDetailCollectionViewLayout:self layoutForSection:section];
    NSUInteger columnCount = layout.ItemArea.Grid.ColumnCount;
    
    return (item % columnCount);
}


- (NSUInteger)rowForItem:(NSUInteger)item section:(BLMProjectDetailSection)section {
    BLMCollectionViewSectionLayout layout = [self.layoutDelegate projectDetailCollectionViewLayout:self layoutForSection:section];
    NSUInteger columnCount = layout.ItemArea.Grid.ColumnCount;
    
    return (item / columnCount);
}

@end
