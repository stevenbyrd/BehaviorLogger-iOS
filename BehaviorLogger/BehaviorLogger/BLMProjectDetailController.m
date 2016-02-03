//
//  BLMProjectDetailController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMBehavior.h"
#import "BLMButtonCell.h"
#import "BLMCollectionViewCell.h"
#import "BLMDataManager.h"
#import "BLMPaddedTextField.h"
#import "BLMProject.h"
#import "BLMProjectDetailController.h"
#import "BLMProjectMenuController.h"
#import "BLMSession.h"
#import "BLMTextInputCell.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"


/*
 ` ### Anatomy of UICollectionView Sections
 `
 ` Header Origin -> *--------------------------* <- Section Width
 `                  |          Header          |
 ` Header Height -> *--------------------------*
 `                  |                          |
 `                  |   *..................*   |
 `                  |   .   Content Area   .   |
 `                  |   .   ............   .   |
 `                  |   .   .          .   .   |
 `                  |   .   .   Item   .   .   |
 `                  |   .   .   Grid   .   .   |
 `                  |   .   .          .   .   |
 `                  |   .   .          .   .   |
 `                  |   .   ............   .   |
 `                  |   .[Item Grid Insets].   |
 `                  |   *..................*   |
 `                  |  [Content Area Insets]   |
 ` Footer Origin -> *--------------------------*
 `                  |          Footer          |
 ` Footer Height -> *--------------------------* <- Section Height
 `
 */


#pragma mark Supplementary View

static NSString *const SectionHeaderViewType = @"SectionHeaderViewType";
static NSString *const SectionSeparatorViewType = @"SectionSeparatorViewType";
static NSString *const SectionBackgroundViewType = @"SectionBackgroundViewType";

typedef NS_ENUM(NSInteger, SupplementaryViewItem) {
    SupplementaryViewItemSectionHeader = -1,
    SupplementaryViewItemSectionBackground = -2,
    SupplementaryViewItemSectionFooter = -3,
    SupplementaryViewItemCount = -4
};

static CGFloat const SectionHeaderHeight = 30.0;
static CGFloat const SectionHeaderTitleFontSize = 18.0;
static CGFloat const SectionHeaderTitleBaselineInset = 9.5;
static CGFloat const SectionHeaderTitleLeftInset = 10.0;

static CGFloat const SectionSeparatorHeight = 1.0;
static CGFloat const SectionSeparatorLeftInset = 30.0;
static CGFloat const SectionSeparatorRightInset = 30.0;


#pragma mark

typedef struct ItemGridLayout {
    NSInteger const ColumnCount;
    CGFloat const ColumnSpacing;
    CGFloat const RowSpacing;
    CGFloat const RowHeight;
    UIEdgeInsets const Insets;
} ItemGridLayout;


typedef struct ContentAreaLayout {
    BOOL const HasBackground;
    UIEdgeInsets const Insets;
    ItemGridLayout const ItemGrid;
} ContentAreaLayout;


typedef struct SectionLayout {
    CGFloat const HeaderHeight;
    ContentAreaLayout const ContentArea;
    CGFloat const FooterHeight;
} SectionLayout;


static SectionLayout const SectionLayoutNull;


#pragma mark

typedef NS_ENUM(NSInteger, ProjectDetailSection) {
    ProjectDetailSectionBasicInfo,
    ProjectDetailSectionSessionProperties,
    ProjectDetailSectionBehaviors,
    ProjectDetailSectionActionButtons,
    ProjectDetailSectionCount
};


typedef NS_ENUM(NSInteger, BasicInfoSectionItem) {
    BasicInfoSectionItemProjectName,
    BasicInfoSectionItemClientName,
    BasicInfoSectionItemCount
};


typedef NS_ENUM(NSInteger, SessionPropertiesSectionItem) {
    SessionPropertiesSectionItemCondition,
    SessionPropertiesSectionItemLocation,
    SessionPropertiesSectionItemTherapist,
    SessionPropertiesSectionItemObserver,
    SessionPropertiesSectionItemCount
};


typedef NS_ENUM(NSInteger, ActionButtonsSectionItem) {
    ActionButtonsSectionItemCreateSession,
    ActionButtonsSectionItemViewSessionHistory,
    ActionButtonsSectionItemDeleteProject,
    ActionButtonsSectionItemCount
};


#pragma mark

@interface SectionHeaderView : UICollectionReusableView

@property (nonatomic, strong, readonly) UILabel *label;

@end


@implementation SectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeBlue alpha:0.3].CGColor;

    _label = [[UILabel alloc] initWithFrame:CGRectZero];

    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.label.textColor = [UIColor darkTextColor];
    self.label.font = [UIFont boldSystemFontOfSize:SectionHeaderTitleFontSize];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.label];
    [self addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeLeft equalToItem:self constant:SectionHeaderTitleLeftInset]];
    [self addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeBaseline equalToItem:self attribute:NSLayoutAttributeBottom constant:-SectionHeaderTitleBaselineInset]];

    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];

    self.label.preferredMaxLayoutWidth = CGRectGetWidth([self.label alignmentRectForFrame:self.label.frame]);

    [super layoutSubviews];
}

@end


#pragma mark

@interface SectionSeparatorView : UICollectionReusableView

@end


@implementation SectionSeparatorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    UIView *separatorView = [[UIView alloc] init];

    separatorView.backgroundColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeBlue alpha:0.3];
    separatorView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:separatorView];
    [self addConstraint:[BLMViewUtils constraintWithItem:separatorView attribute:NSLayoutAttributeLeft equalToItem:self constant:SectionSeparatorLeftInset]];
    [self addConstraint:[BLMViewUtils constraintWithItem:separatorView attribute:NSLayoutAttributeRight equalToItem:self constant:-SectionSeparatorRightInset]];
    [self addConstraint:[BLMViewUtils constraintWithItem:separatorView attribute:NSLayoutAttributeBottom equalToItem:self constant:0.0]];
    [self addConstraint:[BLMViewUtils constraintWithItem:separatorView attribute:NSLayoutAttributeHeight equalToConstant:1.0]];
    
    return self;
}

@end


#pragma mark

@interface SectionBackgroundView : UICollectionReusableView

@end


@implementation SectionBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    self.layer.backgroundColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeDarkBackground alpha:1.0].CGColor;
    self.layer.cornerRadius = 10.0;

    return self;
}

@end


#pragma mark

@interface EditBehaviorCell : BLMCollectionViewCell

@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, strong, readonly) UISwitch *toggleSwitch;

@end


@implementation EditBehaviorCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    self.contentView.layer.borderWidth = 0.0;
    self.contentView.backgroundColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodePurple alpha:1.0];

    return self;
}

@end


#pragma mark

@class ProjectDetailCollectionViewLayout;


@protocol ProjectDetailCollectionViewLayoutDelegate <UICollectionViewDelegate>

- (SectionLayout)projectDetailCollectionViewLayout:(ProjectDetailCollectionViewLayout *)layout layoutForSection:(ProjectDetailSection)section;

@end


@interface ProjectDetailCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, weak, readonly) id<ProjectDetailCollectionViewLayoutDelegate> layoutDelegate;
@property (nonatomic, assign, readonly) CGSize collectionViewContentSize;
@property (nonatomic, copy, readonly) NSMutableArray<NSValue *> *sectionFrameList;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *itemAttributesByIndexPath;
@property (nonatomic, copy, readonly) NSDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *previousItemAttributesByIndexPath;

@end


@implementation ProjectDetailCollectionViewLayout

- (instancetype)init {
    self = [super init];
    if (self == nil)
        return nil;

    _collectionViewContentSize = CGSizeZero;
    _sectionFrameList = [NSMutableArray array];

    return self;
}


- (void)prepareLayout {
    [super prepareLayout];



    [self.sectionFrameList removeAllObjects];

    _previousItemAttributesByIndexPath = self.itemAttributesByIndexPath;
    _itemAttributesByIndexPath = [NSMutableDictionary dictionary];

    _collectionViewContentSize = (CGSize) {
        .width = CGRectGetWidth(self.collectionView.bounds),
        .height = 0.0
    };

    for (ProjectDetailSection section = 0; section < ProjectDetailSectionCount; section += 1) {
        SectionLayout Layout = [self.layoutDelegate projectDetailCollectionViewLayout:self layoutForSection:section];

#pragma mark Section Header Layout

        CGRect headerFrame = {
            .origin = {
                .x = CGRectGetMinX(self.collectionView.bounds),
                .y = _collectionViewContentSize.height // Positioned below previous section at the bottom edge of collectionViewContentSize, the height of which will later increase to accomodate this section
            },
            .size = {
                .width = CGRectGetWidth(self.collectionView.bounds),
                .height = Layout.HeaderHeight
            }
        };

        if (CGRectGetHeight(headerFrame)) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:SupplementaryViewItemSectionHeader inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:SectionHeaderViewType withIndexPath:indexPath];

            attributes.frame = headerFrame;

            self.itemAttributesByIndexPath[indexPath] = attributes;
        }

#pragma mark Content Area Layout

        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        NSInteger rowCount = ceilf(itemCount / (CGFloat)Layout.ContentArea.ItemGrid.ColumnCount);

        CGRect contentAreaFrame = {
            .origin = {
                .x = CGRectGetMinX(self.collectionView.bounds) + Layout.ContentArea.Insets.left, // Shifted right by item area inset
                .y = (CGRectGetMaxY(headerFrame) + Layout.ContentArea.Insets.top) // Positioned below the header and shifted down by item area top inset
            },
            .size = {
                .width = (CGRectGetWidth(self.collectionView.bounds) - Layout.ContentArea.Insets.left - Layout.ContentArea.Insets.right), // Width reduced by item area left/right insets
                .height = ((rowCount * Layout.ContentArea.ItemGrid.RowHeight) // Space necessary for the item grid rows...
                           + (Layout.ContentArea.ItemGrid.RowSpacing * (rowCount - 1)) // ...plus the space necessary for the item grid row spacing...
                           + Layout.ContentArea.ItemGrid.Insets.top + Layout.ContentArea.ItemGrid.Insets.bottom) // ...plus the splace necessary for the item grid insets
            }
        };

        assert(CGRectGetWidth(self.collectionView.bounds) == (CGRectGetWidth(contentAreaFrame) + Layout.ContentArea.Insets.left + Layout.ContentArea.Insets.right));

        if (Layout.ContentArea.HasBackground) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:SupplementaryViewItemSectionBackground inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:SectionBackgroundViewType withIndexPath:indexPath];

            attributes.frame = contentAreaFrame;

            self.itemAttributesByIndexPath[indexPath] = attributes;
        }

#pragma mark Item Grid Layout

        CGRect itemGridFrame = {
            .origin = {
                .x = (CGRectGetMinX(contentAreaFrame) + Layout.ContentArea.ItemGrid.Insets.left),
                .y = (CGRectGetMinY(contentAreaFrame) + Layout.ContentArea.ItemGrid.Insets.top)
            },
            .size = {
                .width = (CGRectGetWidth(contentAreaFrame) - Layout.ContentArea.ItemGrid.Insets.left - Layout.ContentArea.ItemGrid.Insets.right),
                .height = (CGRectGetHeight(contentAreaFrame) - Layout.ContentArea.ItemGrid.Insets.top - Layout.ContentArea.ItemGrid.Insets.bottom)
            }
        };

        CGFloat itemWidth = ((CGRectGetWidth(itemGridFrame) // To find the width of item cells in this section, start with the item area width...
                              - (Layout.ContentArea.ItemGrid.ColumnSpacing * (Layout.ContentArea.ItemGrid.ColumnCount - 1))) // ...then isolate the horizontal space available to item cells by subtracting the inter-column item spacing...
                             / Layout.ContentArea.ItemGrid.ColumnCount); // ...and divide the remaining space by the number of columns

        for (NSInteger item = 0; item < itemCount; item += 1) {
            CGRect itemFrame = {
                .origin = {
                    .x = (CGRectGetMinX(itemGridFrame) + ((itemWidth + Layout.ContentArea.ItemGrid.ColumnSpacing) * [self columnForItem:item section:section])), // Move from left edge to appropriate column
                    .y = (CGRectGetMinY(itemGridFrame) + ((Layout.ContentArea.ItemGrid.RowHeight + Layout.ContentArea.ItemGrid.RowSpacing) * [self rowForItem:item section:section])) // Move from top edge to appropriate row
                },
                .size = {
                    .width = itemWidth,
                    .height = Layout.ContentArea.ItemGrid.RowHeight
                }
            };

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

            attributes.frame = itemFrame;
            attributes.zIndex = 1;

            self.itemAttributesByIndexPath[indexPath] = attributes;
        }

#pragma mark Section Footer Layout

        CGRect footerFrame = {
            .origin = {
                .x = CGRectGetMinX(self.collectionView.bounds),
                .y = (CGRectGetMaxY(contentAreaFrame) + Layout.ContentArea.Insets.bottom) // Footer positioned below item area, shifted down by item area bottom inset
            },
            .size = {
                .width = CGRectGetWidth(self.collectionView.bounds),
                .height = Layout.FooterHeight
            }
        };

        if (CGRectGetHeight(footerFrame) > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:SupplementaryViewItemSectionFooter inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:SectionSeparatorViewType withIndexPath:indexPath];

            attributes.frame = footerFrame;

            self.itemAttributesByIndexPath[indexPath] = attributes;
        }

#pragma mark Section Frame Layout

        CGRect sectionFrame = {
            .origin = headerFrame.origin,
            .size = {
                .width = CGRectGetWidth(self.collectionView.bounds),
                .height = (CGRectGetHeight(headerFrame)
                           + Layout.ContentArea.Insets.top
                           + CGRectGetHeight(contentAreaFrame)
                           + Layout.ContentArea.Insets.bottom
                           + CGRectGetHeight(footerFrame))
            }
        };

        [self.sectionFrameList addObject:[NSValue valueWithCGRect:sectionFrame]];

        _collectionViewContentSize.height += CGRectGetHeight(sectionFrame); // Increase the height of collectionViewContentSize to accomodate the added section

        assert(CGRectGetMaxY(sectionFrame) == _collectionViewContentSize.height);
        assert(CGRectGetMaxY(sectionFrame) == CGRectGetMaxY(footerFrame));
    }
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<UICollectionViewLayoutAttributes *> *attributesForRect = [NSMutableArray array];
    BOOL scannedPastRectMaxY = NO;

    for (ProjectDetailSection section = 0; ((section < ProjectDetailSectionCount) && !scannedPastRectMaxY); section += 1) {
        CGRect sectionFrame = self.sectionFrameList[section].CGRectValue;

        if (CGRectGetMinY(sectionFrame) > CGRectGetMaxY(rect)) {
            scannedPastRectMaxY = YES;
            break;
        }

        if (!CGRectIntersectsRect(sectionFrame, rect)) {
            continue;
        }

        for (NSInteger item = SupplementaryViewItemCount; item < [self.collectionView numberOfItemsInSection:section]; item += 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = self.itemAttributesByIndexPath[indexPath];

            if (attributes == nil) {
                continue;
            }

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
    UICollectionViewLayoutAttributes *attributes = self.itemAttributesByIndexPath[indexPath];
    assert(attributes != nil);

    return attributes;
}


- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *initialAttributes = self.previousItemAttributesByIndexPath[indexPath];

    switch ((ProjectDetailSection)indexPath.section) {
        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionActionButtons:
            break;

        case ProjectDetailSectionBehaviors: {
            NSUInteger secondToLastItem = ([self.collectionView numberOfItemsInSection:indexPath.section] - 2);

            if (initialAttributes == nil) { // The "add behavior" button is the last item; its initial layout for this animation should be the final layout for the cell being added in front of it
                assert(indexPath.item == (secondToLastItem + 1));
                initialAttributes = self.previousItemAttributesByIndexPath[[NSIndexPath indexPathForItem:secondToLastItem inSection:ProjectDetailSectionBehaviors]];
            } else if (indexPath.item == secondToLastItem) {
                initialAttributes = [initialAttributes copy];
                initialAttributes.transform = CGAffineTransformMakeScale(0.01, 0.01);
            }

            break;
        }

        case ProjectDetailSectionCount:
            assert(NO);
            break;
    }

    assert(initialAttributes != nil);
    return initialAttributes;
}


- (nullable UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    return nil;
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return (CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds));
}


- (id<ProjectDetailCollectionViewLayoutDelegate>)layoutDelegate {
    return (id<ProjectDetailCollectionViewLayoutDelegate>)self.collectionView.delegate;
}

#pragma mark Layout Utilities

- (NSUInteger)columnForItem:(NSUInteger)item section:(ProjectDetailSection)section {
    SectionLayout layout = [self.layoutDelegate projectDetailCollectionViewLayout:self layoutForSection:section];
    NSUInteger columnCount = layout.ContentArea.ItemGrid.ColumnCount;

    return (item % columnCount);
}


- (NSUInteger)rowForItem:(NSUInteger)item section:(ProjectDetailSection)section {
    SectionLayout layout = [self.layoutDelegate projectDetailCollectionViewLayout:self layoutForSection:section];
    NSUInteger columnCount = layout.ContentArea.ItemGrid.ColumnCount;
    assert(columnCount > 0);

    return (item / columnCount);
}

@end


#pragma mark

@interface BLMProjectDetailController () <UICollectionViewDataSource, ProjectDetailCollectionViewLayoutDelegate, BLMTextInputCellDelegate, BLMButtonCellDelegate>

@property (nonatomic, strong, readonly) UICollectionView *collectionView;

@property (nonatomic, copy, readonly) NSMutableArray<NSString *> *behaviorNameList;
@property (nonatomic, copy, readonly) NSMutableIndexSet *continuousBehaviorIndexSet;

@end


@implementation BLMProjectDetailController

- (instancetype)initWithProject:(BLMProject *)project {
    NSParameterAssert(project != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUid = project.uid;
    _behaviorNameList = [NSMutableArray array];
    _continuousBehaviorIndexSet = [NSMutableIndexSet indexSet];

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self reloadBehaviorData];

    self.navigationItem.title = @"Project Details";

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[ProjectDetailCollectionViewLayout alloc] init]];

    [self.collectionView registerClass:[SectionHeaderView class] forSupplementaryViewOfKind:SectionHeaderViewType withReuseIdentifier:NSStringFromClass([SectionHeaderView class])];
    [self.collectionView registerClass:[SectionSeparatorView class] forSupplementaryViewOfKind:SectionSeparatorViewType withReuseIdentifier:NSStringFromClass([SectionSeparatorView class])];
    [self.collectionView registerClass:[SectionBackgroundView class] forSupplementaryViewOfKind:SectionBackgroundViewType withReuseIdentifier:NSStringFromClass([SectionBackgroundView class])];

    [self.collectionView registerClass:[EditBehaviorCell class] forCellWithReuseIdentifier:NSStringFromClass([EditBehaviorCell class])];
    [self.collectionView registerClass:[BLMTextInputCell class] forCellWithReuseIdentifier:NSStringFromClass([BLMTextInputCell class])];
    [self.collectionView registerClass:[BLMButtonCell class] forCellWithReuseIdentifier:NSStringFromClass([BLMButtonCell class])];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.scrollEnabled = YES;
    self.collectionView.bounces = YES;
    self.collectionView.backgroundColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeDefaultBackground alpha:1.0];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.collectionView];
    [self.view addConstraints:[BLMViewUtils constraintsForItem:self.collectionView equalToItem:self.view]];

    BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:project];
}


- (void)reloadBehaviorData {
    [self.behaviorNameList removeAllObjects];
    [self.continuousBehaviorIndexSet removeAllIndexes];

    BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];
    NSArray *behaviorList = project.defaultSessionConfiguration.behaviorList;

    [behaviorList enumerateObjectsUsingBlock:^(BLMBehavior *behavior, NSUInteger index, BOOL *stop) {
        [self.behaviorNameList addObject:behavior.name];

        if (behavior.isContinuous) {
            [self.continuousBehaviorIndexSet addIndex:index];
        }
    }];

    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:ProjectDetailSectionBehaviors]];
}

#pragma mark Event Handling

- (void)handleProjectUpdated:(NSNotification *)notification {
    BLMProject *originalProject = (BLMProject *)notification.userInfo[BLMProjectOldProjectUserInfoKey];
    assert(originalProject == notification.object);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMProjectUpdatedNotification object:originalProject];

    BLMProject *updatedProject = (BLMProject *)notification.userInfo[BLMProjectNewProjectUserInfoKey];
    assert(updatedProject == [[BLMDataManager sharedManager] projectForUid:self.projectUid]);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:updatedProject];

    [self reloadBehaviorData];

    //TODO: Update UI
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return ProjectDetailSectionCount;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = 0;

    switch ((ProjectDetailSection)section) {
        case ProjectDetailSectionBasicInfo: {
            numberOfItems = BasicInfoSectionItemCount;
            break;
        }

        case ProjectDetailSectionSessionProperties: {
            numberOfItems = SessionPropertiesSectionItemCount;
            break;
        }

        case ProjectDetailSectionBehaviors: {
            numberOfItems = self.behaviorNameList.count;
            numberOfItems += 1; // Add one for the AddBehaviorCell
            break;
        }

        case ProjectDetailSectionActionButtons: {
            numberOfItems = ActionButtonsSectionItemCount;
            break;
        }

        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return numberOfItems;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BLMCollectionViewCell *cell = nil;

    switch ((ProjectDetailSection)indexPath.section) {
        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties: {
            BLMTextInputCell *textInputCell = (BLMTextInputCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMTextInputCell class]) forIndexPath:indexPath];
            textInputCell.delegate = self;

            cell = textInputCell;
            break;
        }

        case ProjectDetailSectionBehaviors: {
            if (indexPath.item < self.behaviorNameList.count) {
                EditBehaviorCell *behaviorCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([EditBehaviorCell class]) forIndexPath:indexPath];
                cell = behaviorCell;
            } else {
                assert(indexPath.item == self.behaviorNameList.count);

                BLMButtonCell *buttonCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMButtonCell class]) forIndexPath:indexPath];
                buttonCell.delegate = self;

                cell = buttonCell;
            }

            break;
        }

        case ProjectDetailSectionActionButtons: {
            BLMButtonCell *buttonCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMButtonCell class]) forIndexPath:indexPath];
            buttonCell.delegate = self;

            cell = buttonCell;
            break;
        }

        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    cell.section = indexPath.section;
    cell.item = indexPath.item;

    [cell updateContent];

    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = nil;

    if ([kind isEqualToString:SectionHeaderViewType]) {
        SectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([SectionHeaderView class]) forIndexPath:indexPath];

        view = headerView;

        switch ((ProjectDetailSection)indexPath.section) {
            case ProjectDetailSectionBasicInfo: {
                assert(NO);
                break;
            }

            case ProjectDetailSectionSessionProperties: {
                headerView.label.text = @"Default Session Properties";
                break;
            }

            case ProjectDetailSectionBehaviors: {
                headerView.label.text = @"Behaviors";
                break;
            }

            case ProjectDetailSectionActionButtons: {
                assert(NO);
                break;
            }
                
            case ProjectDetailSectionCount: {
                assert(NO);
                break;
            }
        }
    } else if ([kind isEqualToString:SectionSeparatorViewType]) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([SectionSeparatorView class]) forIndexPath:indexPath];
    } else if ([kind isEqualToString:SectionBackgroundViewType]) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([SectionBackgroundView class]) forIndexPath:indexPath];
    }

    assert(view != nil);
    return view;
}

#pragma mark ProjectDetailCollectionViewLayoutDelegate

- (SectionLayout)projectDetailCollectionViewLayout:(ProjectDetailCollectionViewLayout *)layout layoutForSection:(ProjectDetailSection)section {
    switch (section) {
        case ProjectDetailSectionBasicInfo: {
            return (SectionLayout) {
                .HeaderHeight = 0.0,
                .FooterHeight = 0.0,
                .ContentArea = {
                    .HasBackground = NO,
                    .Insets = {
                        .top = 20.0,
                        .left = 30.0,
                        .bottom = 20.0,
                        .right = 30.0
                    },
                    .ItemGrid = {
                        .ColumnCount = 2,
                        .ColumnSpacing = 20.0,
                        .RowSpacing = 0.0,
                        .RowHeight = 40.0,
                        .Insets = UIEdgeInsetsZero
                    }
                }
            };
        }

        case ProjectDetailSectionSessionProperties: {
            return (SectionLayout) {
                .HeaderHeight = SectionHeaderHeight,
                .FooterHeight = 0.0,
                .ContentArea = {
                    .HasBackground = NO,
                    .Insets = {
                        .top = 10.0,
                        .left = 30.0,
                        .bottom = 10.0,
                        .right = 30.0
                    },
                    .ItemGrid = {
                        .ColumnCount = 2,
                        .ColumnSpacing = 20.0,
                        .RowSpacing = 10.0,
                        .RowHeight = 40.0,
                        .Insets = UIEdgeInsetsZero
                    }
                }
            };
        }

        case ProjectDetailSectionBehaviors: {
            return (SectionLayout) {
                .HeaderHeight = SectionHeaderHeight,
                .FooterHeight = SectionSeparatorHeight,
                .ContentArea = {
                    .HasBackground = YES,
                    .Insets = {
                        .top = 10.0,
                        .left = 30.0,
                        .bottom = 10.0,
                        .right = 30.0
                    },
                    .ItemGrid = {
                        .ColumnCount = 6,
                        .ColumnSpacing = 10.0,
                        .RowSpacing = 10.0,
                        .RowHeight = 60.0,
                        .Insets = {
                            .top = 10.0,
                            .left = 10.0,
                            .bottom = 10.0,
                            .right = 10.0
                        }
                    }
                }
            };
        }

        case ProjectDetailSectionActionButtons: {
            return (SectionLayout) {
                .HeaderHeight = 0.0,
                .FooterHeight = 0.0,
                .ContentArea = {
                    .HasBackground = NO,
                    .Insets = {
                        .top = 10.0,
                        .left = 30.0,
                        .bottom = 10.0,
                        .right = 30.0
                    },
                    .ItemGrid = {
                        .ColumnCount = 3,
                        .ColumnSpacing = 0.0,
                        .RowSpacing = 10.0,
                        .RowHeight = 40.0,
                        .Insets = UIEdgeInsetsZero
                    }
                }
            };
        }

        case ProjectDetailSectionCount: {
            assert(NO);
            return SectionLayoutNull;
        }
    }
}

#pragma mark BLMTextInputCellDelegate

- (NSString *)labelForTextInputCell:(BLMTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo: {
            switch ((BasicInfoSectionItem)cell.item) {
                case BasicInfoSectionItemProjectName:
                    return @"Project Name:";

                case BasicInfoSectionItemClientName:
                    return @"Client Name:";

                case BasicInfoSectionItemCount: {
                    break;
                }
            }
        }

        case ProjectDetailSectionSessionProperties: {
            switch ((SessionPropertiesSectionItem)cell.item) {
                case SessionPropertiesSectionItemCondition:
                    return @"Condition:";

                case SessionPropertiesSectionItemLocation:
                    return @"Location:";

                case SessionPropertiesSectionItemTherapist:
                    return @"Therapist:";

                case SessionPropertiesSectionItemObserver:
                    return @"Observer";

                case SessionPropertiesSectionItemCount: {
                    break;
                }
            }
        }

        case ProjectDetailSectionBehaviors:
        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    assert(NO);
    return nil;
}


- (NSString *)defaultInputForTextInputCell:(BLMTextInputCell *)cell {
    BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];

    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo: {
            switch ((BasicInfoSectionItem)cell.item) {
                case BasicInfoSectionItemProjectName:
                    return project.name;

                case BasicInfoSectionItemClientName:
                    return project.client;

                case BasicInfoSectionItemCount: {
                    break;
                }
            }
        }

        case ProjectDetailSectionSessionProperties: {
            switch ((SessionPropertiesSectionItem)cell.item) {
                case SessionPropertiesSectionItemCondition:
                    return project.defaultSessionConfiguration.condition;

                case SessionPropertiesSectionItemLocation:
                    return project.defaultSessionConfiguration.location;

                case SessionPropertiesSectionItemTherapist:
                    return project.defaultSessionConfiguration.therapist;

                case SessionPropertiesSectionItemObserver:
                    return project.defaultSessionConfiguration.observer;

                case SessionPropertiesSectionItemCount: {
                    break;
                }
            }
        }

        case ProjectDetailSectionBehaviors:
        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    assert(NO);
    return nil;
}


- (NSUInteger)minimumInputLengthForTextInputCell:(BLMTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo: {
            switch ((BasicInfoSectionItem)cell.item) {
                case BasicInfoSectionItemProjectName:
                    return BLMProjectNameMinimumLength;

                case BasicInfoSectionItemClientName:
                    return BLMProjectClientMinimumLength;

                case BasicInfoSectionItemCount: {
                    break;
                }
            }
        }

        case ProjectDetailSectionSessionProperties: {
            switch ((SessionPropertiesSectionItem)cell.item) {
                case SessionPropertiesSectionItemCondition:
                case SessionPropertiesSectionItemLocation:
                case SessionPropertiesSectionItemTherapist:
                case SessionPropertiesSectionItemObserver:
                    return 0;

                case SessionPropertiesSectionItemCount: {
                    break;
                }
            }
        }

        case ProjectDetailSectionBehaviors:
        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    assert(NO);
    return NSNotFound;
}


- (void)didAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];
    BLMProjectProperty updatedProperty = BLMProjectPropertyCount;
    id updatedValue = nil;

    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo: {
            switch ((BasicInfoSectionItem)cell.item) {
                case BasicInfoSectionItemProjectName:
                    updatedProperty = BLMProjectPropertyName;
                    break;

                case BasicInfoSectionItemClientName:
                    updatedProperty = BLMProjectPropertyClient;
                    break;

                case BasicInfoSectionItemCount: {
                    assert(NO);
                    break;
                }
            }

            updatedValue = cell.textField.text;
            break;
        }

        case ProjectDetailSectionSessionProperties: {
            BLMSessionConfigurationProperty updatedSessionConfigurationProperty;

            switch ((SessionPropertiesSectionItem)cell.item) {
                case SessionPropertiesSectionItemCondition:
                    updatedSessionConfigurationProperty = BLMSessionConfigurationPropertyCondition;
                    break;

                case SessionPropertiesSectionItemLocation:
                    updatedSessionConfigurationProperty = BLMSessionConfigurationPropertyLocation;
                    break;

                case SessionPropertiesSectionItemTherapist:
                    updatedSessionConfigurationProperty = BLMSessionConfigurationPropertyTherapist;
                    break;

                case SessionPropertiesSectionItemObserver:
                    updatedSessionConfigurationProperty = BLMSessionConfigurationPropertyObserver;
                    break;

                case SessionPropertiesSectionItemCount: {
                    assert(NO);
                    break;
                }
            }

            updatedProperty = BLMProjectPropertyDefaultSessionConfiguration;
            updatedValue = [project.defaultSessionConfiguration copyWithUpdatedValuesByProperty:@{ @(updatedSessionConfigurationProperty):(cell.textField.text ?: @"") }];
            break;
        }

        case ProjectDetailSectionBehaviors:
        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    assert(updatedProperty < BLMProjectPropertyCount);
    assert(updatedValue != nil);

    [[BLMDataManager sharedManager] applyUpdateForProjectUid:self.projectUid property:updatedProperty value:updatedValue];
}

#pragma mark BLMButtonCellDelegate

- (UIImage *)normalImageForButtonCell:(BLMButtonCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors: {
            assert(cell.item == self.behaviorNameList.count);

            static UIImage *normalPlusSignImage;
            static dispatch_once_t onceToken;

            dispatch_once(&onceToken, ^{
                normalPlusSignImage = [BLMViewUtils plusSignImageWithColor:[BLMViewUtils colorWithHexValue:BLMColorHexCodeGreen alpha:1.0]];
            });

            return normalPlusSignImage;
        }

        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionActionButtons: {
            break;
        }

        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return nil;
}


- (UIImage *)highlightedImageForButtonCell:(BLMButtonCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors: {
            assert(cell.item == self.behaviorNameList.count);

            static UIImage *highlightedPlusSignImage;
            static dispatch_once_t onceToken;

            dispatch_once(&onceToken, ^{
                highlightedPlusSignImage = [BLMViewUtils plusSignImageWithColor:[BLMViewUtils colorWithHexValue:BLMColorHexCodePurple alpha:1.0]];
            });

            return highlightedPlusSignImage;
        }

        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionActionButtons: {
            break;
        }

        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return nil;
}


- (NSString *)titleForButtonCell:(BLMButtonCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionActionButtons: {
            switch ((ActionButtonsSectionItem)cell.item) {
                case ActionButtonsSectionItemCreateSession:
                    return @"Create Session";
                case ActionButtonsSectionItemViewSessionHistory:
                    return @"View Session History";
                case ActionButtonsSectionItemDeleteProject:
                    return @"Delete Project";
                case ActionButtonsSectionItemCount:
                    assert(NO);
                    return nil;
            }
        }

        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionBehaviors: {
            break;
        }

        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return nil;
}


- (void)didFireActionForButtonCell:(BLMButtonCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors: {
            assert(cell.item == self.behaviorNameList.count);

            NSString *lastBehaviorName = self.behaviorNameList.lastObject;
            if ([BLMUtils isString:lastBehaviorName equalToString:@""]) {
//                return;
            }

            [self.behaviorNameList addObject:@""];
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cell.item inSection:ProjectDetailSectionBehaviors]]];

            cell.item += 1;
            assert(cell.item == self.behaviorNameList.count);
            break;
        }

        case ProjectDetailSectionActionButtons: {
            switch ((ActionButtonsSectionItem)cell.item) {
                case ActionButtonsSectionItemCreateSession:
                    NSLog(@"");
                    break;
                case ActionButtonsSectionItemViewSessionHistory:
                    NSLog(@"");
                    break;
                case ActionButtonsSectionItemDeleteProject:
                    NSLog(@"");
                    break;
                case ActionButtonsSectionItemCount:
                    assert(NO);
                    break;
            }

            break;
        }

        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
}

@end
