//
//  BLMProjectDetailController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMBehavior.h"
#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMProjectDetailController.h"
#import "BLMProjectMenuController.h"
#import "BLMSession.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"


/*
 ` ### Anatomy of UICollectionView Sections
 `
 ` Header Origin -> *--------------------------* <- Section Width
 `                  |           Header         |
 ` Header Height -> *--------------------------*
 `                  |      Top Item Inset      |
 `                  |   *..................*   |
 `                  |   .                  .   |
 `                  | L .                  . R |
 `                  |   .                  .   |
 `                  | I .     Item Area    . I |
 `                  | n .                  . n |
 `                  | s . (Dynamic Height) . s |
 `                  | e .                  . e |
 `                  | t .                  . t |
 `                  |   .                  .   |
 `                  |   *..................*   |
 `                  |     Bottom Item Inset    |
 ` Footer Origin -> *--------------------------*
 `                  |          Footer          |
 ` Footer Height -> *--------------------------* <- Section Height
 `
 */


#pragma mark Supplementary View

static NSInteger const SupplementaryViewIndexPathItem = -1;

static CGFloat const SectionHeaderHeight = 10.0;
static CGFloat const SectionHeaderFontSize = 14.0;
static CGFloat const SectionHeaderBaselineOffset = -9.5;
static CGFloat const SectionHeaderSeparatorHeight = 1.0;

static float const SectionFooterHeight = 10.0;


#pragma mark Section Item Layout

typedef struct ItemAreaLayout {
    NSUInteger const    ColumnCount;
    CGFloat const       ItemHeight;
    CGFloat const       ItemSpacing;
    UIEdgeInsets const  Insets;
} ItemAreaLayout;


static ItemAreaLayout const ItemAreaLayoutNull;


static ItemAreaLayout const BasicInfoItemAreaLayout = {
    .ColumnCount = 2,
    .ItemHeight = 60.0,
    .ItemSpacing = 3.0,
    .Insets = {
        .top = 0.0,
        .left = 8.0,
        .bottom = 0.0,
        .right = 8.0
    }
};

static ItemAreaLayout const SessionPropertiesItemAreaLayout = {
    .ColumnCount = 2,
    .ItemHeight = 60.0,
    .ItemSpacing = 3.0,
    .Insets = {
        .top = 0.0,
        .left = 8.0,
        .bottom = 0.0,
        .right = 8.0
    }
};

static ItemAreaLayout const BehaviorsItemAreaLayout = {
    .ColumnCount = 2,
    .ItemSpacing = 3.0,
    .ItemHeight = 60.0,
    .Insets = {
        .top = 0.0,
        .left = 8.0,
        .bottom = 0.0,
        .right = 8.0
    }
};

static ItemAreaLayout const ActionButtonsItemAreaLayout = {
    .ColumnCount = 2,
    .ItemSpacing = 3.0,
    .ItemHeight = 40.0,
    .Insets = {
        .top = 0.0,
        .left = 100.0,
        .bottom = 0.0,
        .right = 100.0
    }
};


#pragma mark

@implementation BLMProjectDetailCollectionViewLayout

- (instancetype)init {
    self = [super init];
    if (self == nil)
        return nil;

    _collectionViewContentSize = CGSizeZero;
    _sectionFrameList = [NSMutableArray array];
    _sessionIndexPathList = [NSMutableArray array];
    _itemAttributesByIndexPath = [NSMutableDictionary dictionary];
    _supplementaryViewAttributesByIndexPathByKind = @{ UICollectionElementKindSectionHeader : [NSMutableDictionary dictionary], UICollectionElementKindSectionFooter : [NSMutableDictionary dictionary] };

    return self;
}


- (void)prepareLayout {
    [super prepareLayout];

    [self.sectionFrameList removeAllObjects];
    [self.sessionIndexPathList removeAllObjects];
    [self.itemAttributesByIndexPath removeAllObjects];
    [self.supplementaryViewAttributesByIndexPathByKind[UICollectionElementKindSectionHeader] removeAllObjects];
    [self.supplementaryViewAttributesByIndexPathByKind[UICollectionElementKindSectionFooter] removeAllObjects];

    CGSize collectionViewContentSize = {
        .width = CGRectGetWidth(self.collectionView.bounds),
        .height = 0.0
    };

    for (BLMProjectDetailSection section = 0; section < BLMProjectDetailSectionCount; section += 1) {
        [self.sessionIndexPathList addObject:[NSMutableArray array]];

        // Prepare Header Layout

        CGRect headerFrame = {
            .origin = {
                .x = CGRectGetMinX(self.collectionView.bounds),
                .y = collectionViewContentSize.height // Positioned below previous section at the bottom edge of collectionViewContentSize, the height of which will later increase to accomodate this section
            },
            .size = CGSizeZero
        };

        switch (section) {
            case BLMProjectDetailSectionSessionProperties:
            case BLMProjectDetailSectionBehaviors: {
                headerFrame.size = (CGSize) {
                    .width = collectionViewContentSize.width,
                    .height = SectionHeaderHeight
                };

                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:SupplementaryViewIndexPathItem inSection:section];

                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
                attributes.frame = headerFrame;

                self.supplementaryViewAttributesByIndexPathByKind[UICollectionElementKindSectionHeader][indexPath] = attributes;
                [self.sessionIndexPathList[section] addObject:indexPath];

                break;
            }

            case BLMProjectDetailSectionBasicInfo:
            case BLMProjectDetailSectionActionButtons: {
                break;
            }

            case BLMProjectDetailSectionCount: {
                assert(NO);
                break;
            }
        }

        // Prepare Item Area Layout

        ItemAreaLayout const ItemArea = [BLMProjectDetailCollectionViewLayout itemAreaLayoutForSection:section];

        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        NSInteger rowCount = ceilf(itemCount / ItemArea.ColumnCount);

        CGRect itemAreaFrame = {
            .origin = {
                .x = ItemArea.Insets.left, // Shifted right by item area inset
                .y = (CGRectGetMaxY(headerFrame) + ItemArea.Insets.top) // Positioned below the header and shifted down by item area top inset
            },
            .size = {
                .width = (collectionViewContentSize.width - ItemArea.Insets.left - ItemArea.Insets.right), // Width reduced by item area left/right insets
                .height = ((rowCount * ItemArea.ItemHeight) + (ItemArea.ItemSpacing * (rowCount - 1))) // Height calculated from item height/spacing and the number of rows required
            }
        };

        assert(collectionViewContentSize.width == (itemAreaFrame.size.width + ItemArea.Insets.left + ItemArea.Insets.right));

        CGFloat itemWidth = ((CGRectGetWidth(itemAreaFrame) // To find the width of item cells in this section, start with the item area width...
                              - (ItemArea.ItemSpacing * (ItemArea.ColumnCount - 1))) // ...then isolate the horizontal space available to item cells by subtracting the item spacing...
                             / ItemArea.ColumnCount); // ...and divide the remaining space by the number of columns

        for (NSUInteger itemIndex = 0; itemIndex < itemCount; itemIndex += 1) {
            NSInteger column = (itemIndex % ItemArea.ColumnCount);
            NSInteger row = (itemIndex / ItemArea.ColumnCount);

            CGRect itemFrame = {
                .origin = {
                    .x = (CGRectGetMinX(itemAreaFrame) + ((itemWidth + ItemArea.ItemSpacing) * column)), // Start out left--aligned with item area frame, then move over to appropriate column
                    .y = (CGRectGetMinY(itemAreaFrame) + ((ItemArea.ItemHeight + ItemArea.ItemSpacing) * row)) // Start out top-aligned with item area frame, then move down to appropriate row
                },
                .size = {
                    .width = itemWidth,
                    .height = ItemArea.ItemHeight
                }
            };

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:section];

            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = itemFrame;

            self.itemAttributesByIndexPath[indexPath] = attributes;
            [self.sessionIndexPathList[section] addObject:indexPath];
        }

        // Prepare Section Footer Layout

        CGRect footerFrame = {
            .origin = {
                .x = 0.0,
                .y = (CGRectGetMaxY(itemAreaFrame) + ItemArea.Insets.bottom) // Footer positioned below item area, shifted down by item area bottom inset
            },
            .size = CGSizeZero
        };

        switch (section) {
            case BLMProjectDetailSectionBasicInfo:
            case BLMProjectDetailSectionSessionProperties:
            case BLMProjectDetailSectionBehaviors: {
                footerFrame.size = (CGSize) {
                    .width = collectionViewContentSize.width,
                    .height = SectionFooterHeight
                };

                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:SupplementaryViewIndexPathItem inSection:0];

                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
                attributes.frame = footerFrame;

                self.supplementaryViewAttributesByIndexPathByKind[UICollectionElementKindSectionFooter][indexPath] = attributes;
                [self.sessionIndexPathList[section] addObject:indexPath];

                break;
            }

            case BLMProjectDetailSectionActionButtons: {
                break;
            }

            case BLMProjectDetailSectionCount: {
                assert(NO);
                break;
            }
        }

        // Calculate Section Frame

        CGRect sectionFrame = {
            .origin = headerFrame.origin,
            .size = {
                .width = collectionViewContentSize.width,
                .height = (CGRectGetHeight(headerFrame)
                           + ItemArea.Insets.top
                           + CGRectGetHeight(itemAreaFrame)
                           + ItemArea.Insets.bottom
                           + CGRectGetHeight(footerFrame))
            }
        };

        [self.sectionFrameList addObject:[NSValue valueWithCGRect:sectionFrame]];

        collectionViewContentSize.height += CGRectGetHeight(sectionFrame); // Increase the height of collectionViewContentSize to accomodate the added section

        assert(CGRectGetMaxY(sectionFrame) == collectionViewContentSize.height);
        assert(CGRectGetMaxY(sectionFrame) == CGRectGetMaxY(footerFrame));
    }

    _collectionViewContentSize = collectionViewContentSize; // Update the collectionViewContentSize property so UICollectionView knows there's something to render
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *headerAttributesByIndexPath = self.supplementaryViewAttributesByIndexPathByKind[UICollectionElementKindSectionHeader];
    NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *footerAttributesByIndexPath = self.supplementaryViewAttributesByIndexPathByKind[UICollectionElementKindSectionFooter];
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

        for (NSIndexPath *indexPath in self.sessionIndexPathList[section]) {
            UICollectionViewLayoutAttributes *attributes = (self.itemAttributesByIndexPath[indexPath] ?: headerAttributesByIndexPath[indexPath] ?: footerAttributesByIndexPath[indexPath]);

            assert(attributes != nil);

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
    UICollectionViewLayoutAttributes *attributes = self.itemAttributesByIndexPath[indexPath];
    assert(attributes != nil);

    return attributes;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = self.supplementaryViewAttributesByIndexPathByKind[elementKind][indexPath];
    assert(attributes != nil);

    return attributes;
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return (CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds));
}

#pragma mark Layout Utilities

+ (ItemAreaLayout const)itemAreaLayoutForSection:(BLMProjectDetailSection)section {
    switch (section) {
        case BLMProjectDetailSectionBasicInfo: {
            return BasicInfoItemAreaLayout;
        }

        case BLMProjectDetailSectionSessionProperties: {
            return SessionPropertiesItemAreaLayout;
        }

        case BLMProjectDetailSectionBehaviors: {
            return BehaviorsItemAreaLayout;
        }

        case BLMProjectDetailSectionActionButtons: {
            return ActionButtonsItemAreaLayout;
        }

        case BLMProjectDetailSectionCount: {
            assert(NO);
            return ItemAreaLayoutNull;
        }
    }
}

@end


#pragma mark

@implementation BLMBasicInfoCell

@end


#pragma mark

@implementation BLMSessionPropertyCell

@end


#pragma mark

@implementation BLMBehaviorCell

@end


#pragma mark

@implementation BLMAddBehaviorCell

@end


#pragma mark

@implementation BLMActionButtonCell

@end


#pragma mark

@implementation BLMSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    _label = [[UILabel alloc] initWithFrame:CGRectZero];

    self.label.font = [UIFont systemFontOfSize:SectionHeaderFontSize];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;

    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self addSubview:self.label];
    [self addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeLeft equalToItem:self constant:0.0]];
    [self addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeWidth equalToItem:self constant:0.0]];
    [self addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeBaseline equalToItem:self attribute:NSLayoutAttributeBottom constant:SectionHeaderBaselineOffset]];

    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectZero];

    separatorView.backgroundColor = [UIColor lightGrayColor];
    separatorView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:separatorView];
    [self addConstraint:[BLMViewUtils constraintWithItem:separatorView attribute:NSLayoutAttributeHeight equalToConstant:SectionHeaderSeparatorHeight]];
    [self addConstraint:[BLMViewUtils constraintWithItem:separatorView attribute:NSLayoutAttributeWidth equalToItem:self constant:0.0]];
    [self addConstraint:[BLMViewUtils constraintWithItem:separatorView attribute:NSLayoutAttributeCenterX equalToItem:self constant:0.0]];
    [self addConstraint:[BLMViewUtils constraintWithItem:separatorView attribute:NSLayoutAttributeBottom equalToItem:self constant:0.0]];

    return self;
}


- (void)prepareForReuse {
    [super prepareForReuse];

    self.label.text = @"<HEADER LABEL TEXT MISSING>";
}


- (void)layoutSubviews {
    NSLog(@"A) Frame: %@", NSStringFromCGRect(self.label.frame));
    [super layoutSubviews];
    NSLog(@"B) Frame: %@", NSStringFromCGRect(self.label.frame));
    self.label.preferredMaxLayoutWidth = CGRectGetWidth([self.label alignmentRectForFrame:self.label.frame]);
    NSLog(@"C) Frame: %@", NSStringFromCGRect(self.label.frame));
    [super layoutSubviews];
    NSLog(@"D) Frame: %@", NSStringFromCGRect(self.label.frame));
    NSLog(@"");
}

@end


#pragma mark

@implementation BLMSectionFooterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }


    return self;
}

@end


#pragma mark

@interface BLMProjectDetailController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong, readonly) UICollectionView *collectionView;

@end


@implementation BLMProjectDetailController

- (instancetype)initWithProject:(BLMProject *)project {
    NSParameterAssert(project != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUid = project.uid;

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[BLMProjectDetailCollectionViewLayout alloc] init]];

    for (Class cellClass in @[[BLMBasicInfoCell class], [BLMSessionPropertyCell class], [BLMBehaviorCell class], [BLMAddBehaviorCell class], [BLMActionButtonCell class]]) {
        [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:NSStringFromClass(cellClass)];
    }

    [self.collectionView registerClass:[BLMSectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([BLMSectionHeaderView class])];
    [self.collectionView registerClass:[BLMSectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass([BLMSectionFooterView class])];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor grayColor];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.collectionView];
    [self.view addConstraints:[BLMViewUtils constraintsForItem:self.collectionView equalToItem:self.view]];

    BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:project];
}

#pragma mark Event Handling

- (void)handleProjectUpdated:(NSNotification *)notification {
    BLMProject *originalProject = (BLMProject *)notification.userInfo[BLMProjectOldProjectUserInfoKey];
    assert(originalProject == notification.object);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMProjectUpdatedNotification object:originalProject];

    BLMProject *updatedProject = (BLMProject *)notification.userInfo[BLMProjectNewProjectUserInfoKey];
    assert(updatedProject == [[BLMDataManager sharedManager] projectForUid:self.projectUid]);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:updatedProject];

    //TODO: Update UI
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = 0;

    switch ((BLMProjectDetailSection)section) {
        case BLMProjectDetailSectionBasicInfo: {
            numberOfItems = BLMBasicInfoSectionItemCount;
            break;
        }

        case BLMProjectDetailSectionSessionProperties: {
            numberOfItems = BLMSessionPropertiesSectionItemCount;
            break;
        }

        case BLMProjectDetailSectionBehaviors: {
            BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];
            NSArray<BLMBehavior *> *behaviorList = project.defaultSessionConfiguration.behaviorList;

            numberOfItems = behaviorList.count;
            numberOfItems += 1; // Add one for the BLMAddBehaviorCell

            break;
        }

        case BLMProjectDetailSectionActionButtons: {
            numberOfItems = BLMActionButtonsSectionItemCount;
            break;
        }

        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return numberOfItems;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;

    switch ((BLMProjectDetailSection)indexPath.section) {
        case BLMProjectDetailSectionBasicInfo: {
            BLMBasicInfoCell *basicInfoCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMBasicInfoCell class]) forIndexPath:indexPath];
            cell = basicInfoCell;
            break;
        }

        case BLMProjectDetailSectionSessionProperties: {
            BLMSessionPropertyCell *sessionPropertyCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMSessionPropertyCell class]) forIndexPath:indexPath];
            cell = sessionPropertyCell;
            break;
        }

        case BLMProjectDetailSectionBehaviors: {
            BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];
            NSArray<BLMBehavior *> *behaviorList = project.defaultSessionConfiguration.behaviorList;

            if (indexPath.item < behaviorList.count) {
                BLMBehaviorCell *behaviorCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMBehaviorCell class]) forIndexPath:indexPath];
                cell = behaviorCell;
            } else {
                assert(indexPath.item == behaviorList.count);
                BLMAddBehaviorCell *createBLMBehaviorCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMAddBehaviorCell class]) forIndexPath:indexPath];
                cell = createBLMBehaviorCell;
            }

            break;
        }

        case BLMProjectDetailSectionActionButtons: {
            BLMActionButtonCell *actionButtonCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMActionButtonCell class]) forIndexPath:indexPath];
            cell = actionButtonCell;
            break;
        }

        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return cell;
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return BLMProjectDetailSectionCount;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = nil;

    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        BLMSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([BLMSectionHeaderView class]) forIndexPath:indexPath];

        view = headerView;

        switch ((BLMProjectDetailSection)indexPath.section) {
            case BLMProjectDetailSectionBasicInfo: {
                break;
            }

            case BLMProjectDetailSectionSessionProperties: {
                headerView.label.text = @"Session Properties";
                break;
            }

            case BLMProjectDetailSectionBehaviors: {
                headerView.label.text = @"Behaviors";
                break;
            }

            case BLMProjectDetailSectionActionButtons: {
                break;
            }

            case BLMProjectDetailSectionCount: {
                assert(NO);
                break;
            }
        }
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        switch ((BLMProjectDetailSection)indexPath.section) {
            case BLMProjectDetailSectionBasicInfo:
            case BLMProjectDetailSectionSessionProperties:
            case BLMProjectDetailSectionBehaviors: {
                view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([BLMSectionFooterView class]) forIndexPath:indexPath];
                break;
            }
                
            case BLMProjectDetailSectionActionButtons: {
                break;
            }
                
            case BLMProjectDetailSectionCount: {
                assert(NO);
                break;
            }
        }
    }
    
    assert(view != nil);
    
    return view;
}

@end
