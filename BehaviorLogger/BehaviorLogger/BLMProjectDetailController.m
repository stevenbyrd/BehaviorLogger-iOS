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

static NSString *const HeaderKind = @"HeaderKind";
static NSString *const ContentBackgroundKind = @"ContentBackgroundKind";
static NSString *const ItemCellKind = @"ItemCellKind";
static NSString *const SeparatorKind = @"SeparatorKind";

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

@class ProjectDetailCollectionViewLayout;


@protocol ProjectDetailCollectionViewLayoutDelegate <UICollectionViewDelegate>

- (SectionLayout)projectDetailCollectionViewLayout:(ProjectDetailCollectionViewLayout *)layout layoutForSection:(ProjectDetailSection)section;

@end


@interface ProjectDetailCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, weak, readonly) id<ProjectDetailCollectionViewLayoutDelegate> layoutDelegate;
@property (nonatomic, assign, readonly) CGSize collectionViewContentSize;
@property (nonatomic, copy, readonly) NSMutableArray<NSValue *> *sectionFrameList;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *> *attributesByIndexPathByKind;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *> *previousAttributesByIndexPathByKind;

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

    _previousAttributesByIndexPathByKind = self.attributesByIndexPathByKind;
    _attributesByIndexPathByKind = @{ HeaderKind:[NSMutableDictionary dictionary], ContentBackgroundKind:[NSMutableDictionary dictionary], ItemCellKind:[NSMutableDictionary dictionary], SeparatorKind:[NSMutableDictionary dictionary] };

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
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:HeaderKind withIndexPath:indexPath];

            attributes.frame = headerFrame;

            self.attributesByIndexPathByKind[HeaderKind][indexPath] = attributes;
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
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:ContentBackgroundKind withIndexPath:indexPath];

            attributes.frame = contentAreaFrame;

            self.attributesByIndexPathByKind[ContentBackgroundKind][indexPath] = attributes;
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
                              - (Layout.ContentArea.ItemGrid.ColumnSpacing // ...then subtracting the horizontal inter-column space...
                                 * (Layout.ContentArea.ItemGrid.ColumnCount - 1))) // ...multiplied by the total number of inter-column spaces...
                             / Layout.ContentArea.ItemGrid.ColumnCount); // ...and finally dividing the remaining space by the number of columns

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

            self.attributesByIndexPathByKind[ItemCellKind][indexPath] = attributes;
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
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:SeparatorKind withIndexPath:indexPath];

            attributes.frame = footerFrame;

            self.attributesByIndexPathByKind[SeparatorKind][indexPath] = attributes;
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

        for (NSString *kind in @[HeaderKind, ContentBackgroundKind, SeparatorKind]) {
            [self.attributesByIndexPathByKind[kind] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *key, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
                if (CGRectIntersectsRect(attributes.frame, rect)) {
                    [attributesForRect addObject:attributes];
                }
            }];
        }

        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];

        for (NSInteger item = 0; item < itemCount; item += 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = self.attributesByIndexPathByKind[ItemCellKind][indexPath];

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
    UICollectionViewLayoutAttributes *attributes = self.attributesByIndexPathByKind[ItemCellKind][indexPath];
    assert(attributes != nil);

    return attributes;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = self.attributesByIndexPathByKind[elementKind][indexPath];
    assert(attributes != nil);

    return attributes;
}


- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *initialAttributes = self.attributesByIndexPathByKind[ItemCellKind][indexPath];

    switch ((ProjectDetailSection)indexPath.section) {
        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionActionButtons:
            break;

        case ProjectDetailSectionBehaviors: {
            if (self.previousAttributesByIndexPathByKind[ItemCellKind].count == self.attributesByIndexPathByKind[ItemCellKind].count) { // Reloading existing item, don't animate
                break;
            }

            NSUInteger secondToLastItem = ([self.collectionView numberOfItemsInSection:indexPath.section] - 2);

            if (initialAttributes == nil) { // The "add behavior" button is the last item; its initial layout for this animation should be the final layout for the cell being added in front of it
                assert(indexPath.item == (secondToLastItem + 1));
                initialAttributes = self.attributesByIndexPathByKind[ItemCellKind][[NSIndexPath indexPathForItem:secondToLastItem inSection:ProjectDetailSectionBehaviors]];
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


- (nullable UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return self.attributesByIndexPathByKind[elementKind][indexPath];
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

@interface BLMProjectDetailController () <UICollectionViewDataSource, ProjectDetailCollectionViewLayoutDelegate, BLMToggleSwitchTextInputCellDelegate, BLMButtonCellDelegate>

@property (nonatomic, strong, readonly) UICollectionView *collectionView;

@property (nonatomic, copy) NSMutableArray<NSString *> *originalBehaviorNameList;
@property (nonatomic, copy) NSMutableArray<NSString *> *updatedBehaviorNameList;
@property (nonatomic, copy) NSMutableIndexSet *continuousBehaviorIndexSet;

@end


@implementation BLMProjectDetailController

- (instancetype)initWithProject:(BLMProject *)project {
    NSParameterAssert(project != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUid = project.uid;
    _originalBehaviorNameList = [NSMutableArray array];
    _updatedBehaviorNameList = [NSMutableArray array];
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

    [self.collectionView registerClass:[SectionHeaderView class] forSupplementaryViewOfKind:HeaderKind withReuseIdentifier:NSStringFromClass([SectionHeaderView class])];
    [self.collectionView registerClass:[SectionSeparatorView class] forSupplementaryViewOfKind:SeparatorKind withReuseIdentifier:NSStringFromClass([SectionSeparatorView class])];
    [self.collectionView registerClass:[SectionBackgroundView class] forSupplementaryViewOfKind:ContentBackgroundKind withReuseIdentifier:NSStringFromClass([SectionBackgroundView class])];

    [self.collectionView registerClass:[BLMToggleSwitchTextInputCell class] forCellWithReuseIdentifier:NSStringFromClass([BLMToggleSwitchTextInputCell class])];
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
    NSString *unfinishedAddedBehaviorName = nil;
    BOOL isUnfinishedBehaviorContinuous = NO;

    if ((self.updatedBehaviorNameList.count > self.originalBehaviorNameList.count) && ![self isValidBehaviorNameAtIndex:(self.updatedBehaviorNameList.count - 1)]) {
        assert(self.updatedBehaviorNameList.count - self.originalBehaviorNameList.count == 1);
        unfinishedAddedBehaviorName = self.updatedBehaviorNameList.lastObject;
        isUnfinishedBehaviorContinuous = [self.continuousBehaviorIndexSet containsIndex:(self.updatedBehaviorNameList.count - 1)];
    }

    [self.originalBehaviorNameList removeAllObjects];
    [self.updatedBehaviorNameList removeAllObjects];
    [self.continuousBehaviorIndexSet removeAllIndexes];

    BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];

    [project.defaultSessionConfiguration.behaviorList enumerateObjectsUsingBlock:^(BLMBehavior *behavior, NSUInteger index, BOOL *stop) {
        NSString *behaviorName = behavior.name;

        [self.originalBehaviorNameList addObject:behaviorName];
        [self.updatedBehaviorNameList addObject:behaviorName];

        if (behavior.isContinuous) {
            [self.continuousBehaviorIndexSet addIndex:index];
        }
    }];

    if (unfinishedAddedBehaviorName != nil) {
        [self.updatedBehaviorNameList addObject:unfinishedAddedBehaviorName];

        if (isUnfinishedBehaviorContinuous) {
            [self.continuousBehaviorIndexSet addIndex:(self.updatedBehaviorNameList.count - 1)];
        }
    }
    
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:ProjectDetailSectionBehaviors]];
}


- (BOOL)isValidBehaviorNameAtIndex:(NSUInteger)index {
    assert(index < self.updatedBehaviorNameList.count);

    NSString *updatedBehaviorName = self.updatedBehaviorNameList[index];

    if (updatedBehaviorName.length < BLMBehaviorNameMinimumLength) {
        return NO;
    }

    for (NSUInteger originalIndex = 0; originalIndex < self.originalBehaviorNameList.count; originalIndex += 1) {
        if ([BLMUtils isString:self.originalBehaviorNameList[originalIndex] equalToString:updatedBehaviorName] && (originalIndex != index)) {
            return NO;
        }
    }

    return YES;
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
            numberOfItems = self.updatedBehaviorNameList.count;
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
            if (indexPath.item < self.updatedBehaviorNameList.count) {
                BLMToggleSwitchTextInputCell *behaviorCell = (BLMToggleSwitchTextInputCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMToggleSwitchTextInputCell class]) forIndexPath:indexPath];
                behaviorCell.delegate = self;
                
                cell = behaviorCell;
            } else {
                assert(indexPath.item == self.updatedBehaviorNameList.count);

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

    if ([kind isEqualToString:HeaderKind]) {
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
    } else if ([kind isEqualToString:SeparatorKind]) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([SectionSeparatorView class]) forIndexPath:indexPath];
    } else if ([kind isEqualToString:ContentBackgroundKind]) {
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
                        .ColumnCount = 4,
                        .ColumnSpacing = 15.0,
                        .RowSpacing = 10.0,
                        .RowHeight = 80.0,
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

#pragma mark BLMToggleSwitchTextInputCellDelegate

- (NSString *)labelForTextInputCell:(BLMTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo: {
            switch ((BasicInfoSectionItem)cell.item) {
                case BasicInfoSectionItemProjectName:
                    return @"Project:";

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
                    return @"Observer:";

                case SessionPropertiesSectionItemCount: {
                    break;
                }
            }
        }

        case ProjectDetailSectionBehaviors:
            assert(cell.item < self.updatedBehaviorNameList.count);
            return @"Continuous:";

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

        case ProjectDetailSectionBehaviors: {
            if (cell.item < self.originalBehaviorNameList.count) {
                return self.originalBehaviorNameList[cell.item];
            }

            return self.updatedBehaviorNameList[cell.item];
        }

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    assert(NO);
    return nil;
}


- (NSString *)placeholderForTextInputCell:(BLMTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo:
            return [NSString stringWithFormat:@"Required (%lu+ characters)", (unsigned long)[self minimumInputLengthForTextInputCell:cell]];

        case ProjectDetailSectionSessionProperties:
            return @"Optional";

        case ProjectDetailSectionBehaviors:
            return [NSString stringWithFormat:@"Name (%lu+ characters)", (unsigned long)[self minimumInputLengthForTextInputCell:cell]];

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
            return BLMBehaviorNameMinimumLength;

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    assert(NO);
    return NSNotFound;
}


- (void)didChangeInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors: {
            assert(cell.item < self.updatedBehaviorNameList.count);
            BOOL originalValidity = [self isValidBehaviorNameAtIndex:cell.item];

            [self.updatedBehaviorNameList replaceObjectAtIndex:cell.item withObject:(cell.textField.text ?: @"")];

            if ([self isValidBehaviorNameAtIndex:cell.item] != originalValidity) {
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.updatedBehaviorNameList.count inSection:ProjectDetailSectionBehaviors]]];
            }
            break;
        }

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionCount: {
            break;
        }
    }
}


- (BOOL)shouldAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo:
            return (cell.textField.text.length >= [self minimumInputLengthForTextInputCell:cell]);

        case ProjectDetailSectionSessionProperties:
            return YES;

        case ProjectDetailSectionBehaviors: {
            if ([BLMUtils isString:[self.updatedBehaviorNameList objectAtIndex:cell.item] equalToString:cell.textField.text]) {
                return [self isValidBehaviorNameAtIndex:cell.item];
            };

            assert((cell.item == self.originalBehaviorNameList.count)
                   || [BLMUtils isString:self.updatedBehaviorNameList[cell.item] equalToString:self.originalBehaviorNameList[cell.item]]);

            return NO; // Model was updated between now and when the cell resigned first responder; its UI will be updated appropriately
        }

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
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
            updatedValue = [project.defaultSessionConfiguration copyWithUpdatedValuesByProperty:@{ @(updatedSessionConfigurationProperty) : (cell.textField.text ?: @"") }];
            break;
        }

        case ProjectDetailSectionBehaviors: {
            NSMutableArray<BLMBehavior *> *behaviorList = ([project.defaultSessionConfiguration.behaviorList mutableCopy] ?: [NSMutableArray array]);
            BLMBehavior *updatedBehavior = [[BLMBehavior alloc] initWithName:self.updatedBehaviorNameList[cell.item] continuous:[self.continuousBehaviorIndexSet containsIndex:cell.item]];

            assert([BLMUtils isString:updatedBehavior.name equalToString:cell.textField.text]);
            assert([self isValidBehaviorNameAtIndex:cell.item]);

            if (cell.item == behaviorList.count) {
                [behaviorList addObject:updatedBehavior];
            } else {
                assert(updatedBehavior.isContinuous == behaviorList[cell.item].isContinuous);
                [behaviorList replaceObjectAtIndex:cell.item withObject:updatedBehavior];
            }

            updatedProperty = BLMProjectPropertyDefaultSessionConfiguration;
            updatedValue = [project.defaultSessionConfiguration copyWithUpdatedValuesByProperty:@{ @(BLMSessionConfigurationPropertyBehaviorList) : behaviorList }];
            break;
        }

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


- (BOOL)defaultToggleStateForToggleSwitchTextInputCell:(BLMToggleSwitchTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors:
            return [self.continuousBehaviorIndexSet containsIndex:cell.item];

        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    assert(NO);
    return NO;
}


- (void)didChangeToggleStateForToggleSwitchTextInputCell:(BLMToggleSwitchTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors: {
            assert([self.continuousBehaviorIndexSet containsIndex:cell.item] != cell.toggleSwitch.isOn);

            if (cell.toggleSwitch.isOn) {
                [self.continuousBehaviorIndexSet addIndex:cell.item];
            } else {
                [self.continuousBehaviorIndexSet removeIndex:cell.item];
            }

            BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];
            NSArray<BLMBehavior *> *originalBehaviorList = (project.defaultSessionConfiguration.behaviorList ?: @[]);
            NSString *updatedName = nil;

            if ([self isValidBehaviorNameAtIndex:cell.item]) { // Can create a new behavior or update and existing one, depending on this cell's index
                updatedName = self.updatedBehaviorNameList[cell.item];
            } else if (cell.item >= originalBehaviorList.count) { // Cannot create new behavior with invalid name, and this cell's index is too large to update an existing one
                return;
            } else { // Updating existing behavior, but keeping original name
                updatedName = originalBehaviorList[cell.item].name;
            }

            NSMutableArray<BLMBehavior *> *updatedBehaviorList = [originalBehaviorList mutableCopy];
            BLMBehavior *updatedBehavior = [[BLMBehavior alloc] initWithName:updatedName continuous:cell.toggleSwitch.isOn];

            if (cell.item >= originalBehaviorList.count) { // Create new behavior
                [updatedBehaviorList addObject:updatedBehavior];
            } else { // Update existing behavior
                [updatedBehaviorList replaceObjectAtIndex:cell.item withObject:updatedBehavior];
            }

            BLMSessionConfiguration *updatedSessionConfiguration = [project.defaultSessionConfiguration copyWithUpdatedValuesByProperty:@{ @(BLMSessionConfigurationPropertyBehaviorList) : updatedBehaviorList }];
            [[BLMDataManager sharedManager] applyUpdateForProjectUid:self.projectUid property:BLMProjectPropertyDefaultSessionConfiguration value:updatedSessionConfiguration];
            break;
        }

        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
}

#pragma mark BLMButtonCellDelegate

- (BOOL)isButtonEnabledForButtonCell:(BLMButtonCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors:
            assert(cell.item == self.updatedBehaviorNameList.count);

            for (NSUInteger index = 0; index < self.updatedBehaviorNameList.count; index += 1) {
                if (![self isValidBehaviorNameAtIndex:index]) {
                    return NO;
                }
            }
            break;

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionBasicInfo:
        case ProjectDetailSectionSessionProperties:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    return YES;
}

- (UIImage *)normalImageForButtonCell:(BLMButtonCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors: {
            assert(cell.item == self.updatedBehaviorNameList.count);

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
            assert(cell.item == self.updatedBehaviorNameList.count);

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
            assert(cell.item == self.updatedBehaviorNameList.count);
            assert((self.updatedBehaviorNameList.count == 0) || [self isValidBehaviorNameAtIndex:(self.updatedBehaviorNameList.count - 1)]);

            if (self.updatedBehaviorNameList.count > self.originalBehaviorNameList.count) { // There is a valid behavior item that has not been officially added to the data model
                NSIndexPath *blankBehaviorIndexPath = [NSIndexPath indexPathForItem:(cell.item - 1) inSection:ProjectDetailSectionBehaviors];
                BLMToggleSwitchTextInputCell *addedBehaviorCell = (BLMToggleSwitchTextInputCell *)[self.collectionView cellForItemAtIndexPath:blankBehaviorIndexPath];

                assert([self isValidBehaviorNameAtIndex:addedBehaviorCell.item]); // Add behavior button should be disabled unless everything in self.updatedBehaviorNameList is valid
                assert(addedBehaviorCell.textField.isFirstResponder); // The "add behavior" must have been enabled in response to the added behavior cell's text becoming valid.

                [addedBehaviorCell.textField resignFirstResponder]; // Resign first responder to force update the data model
            }

            [self.updatedBehaviorNameList addObject:@""];

            NSIndexPath *blankBehaviorIndexPath = [NSIndexPath indexPathForItem:cell.item inSection:ProjectDetailSectionBehaviors];

            [self.collectionView performBatchUpdates:^{
                [self.collectionView insertItemsAtIndexPaths:@[blankBehaviorIndexPath]];
            } completion:^(BOOL finished) {
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.updatedBehaviorNameList.count inSection:ProjectDetailSectionBehaviors]]];
                [self.collectionView scrollToItemAtIndexPath:blankBehaviorIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];

                BLMToggleSwitchTextInputCell *blankBehaviorCell = (BLMToggleSwitchTextInputCell *)[self.collectionView cellForItemAtIndexPath:blankBehaviorIndexPath];
                [blankBehaviorCell.textField becomeFirstResponder];
            }];
            break;
        }

        case ProjectDetailSectionActionButtons: {
            switch ((ActionButtonsSectionItem)cell.item) {
                case ActionButtonsSectionItemCreateSession:
                    break;
                case ActionButtonsSectionItemViewSessionHistory:
                    break;
                case ActionButtonsSectionItemDeleteProject:
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
