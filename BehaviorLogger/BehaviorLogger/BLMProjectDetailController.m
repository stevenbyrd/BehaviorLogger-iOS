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

@class BehaviorCell;


@protocol BehaviorCellDelegate <BLMTextInputCellDelegate>

- (void)didChangeToggleSwitchStateForBehaviorCell:(BehaviorCell *)cell;

@end


@interface BehaviorCell : BLMTextInputCell

@property (nonatomic, strong, readonly) UISwitch *toggleSwitch;
@property (nonatomic, weak) id<BehaviorCellDelegate> delegate;
@property (nonatomic, strong) BLMBehavior *behavior;

@end


@implementation BehaviorCell

@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    [self.contentView removeConstraints:[self.contentView.constraints filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSLayoutConstraint *constraint, NSDictionary<NSString *,id> *bindings) {
        return ([BLMUtils isObject:constraint.firstItem equalToObject:self.label]
                || [BLMUtils isObject:constraint.secondItem equalToObject:self.label]
                || (constraint.firstAttribute == NSLayoutAttributeCenterY));
    }]]];

    _toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];

    [self.toggleSwitch addTarget:self action:@selector(handleValueChangedForToggleSwitch:forEvent:) forControlEvents:UIControlEventTouchUpInside];

    self.toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.toggleSwitch];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.toggleSwitch attribute:NSLayoutAttributeBottom equalToItem:self.contentView constant:-3.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.toggleSwitch attribute:NSLayoutAttributeRight equalToItem:self.textField constant:-3.0]];

    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeCenterY equalToItem:self.toggleSwitch constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.label attribute:NSLayoutAttributeRight equalToItem:self.toggleSwitch attribute:NSLayoutAttributeLeft constant:-8.0]];

    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeTop equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeLeft equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.textField attribute:NSLayoutAttributeBottom equalToItem:self.toggleSwitch attribute:NSLayoutAttributeTop constant:-8.0]];

    self.toggleSwitch.layer.borderWidth = 1.0;
    self.toggleSwitch.layer.borderColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeGreen alpha:0.3].CGColor;

    self.label.layer.borderWidth = 1.0;
    self.label.layer.borderColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeGreen alpha:0.3].CGColor;

    return self;
}


- (void)updateContent {
    [super updateContent];

    self.toggleSwitch.on = self.behavior.isContinuous;
}


- (void)handleValueChangedForToggleSwitch:(UISwitch *)toggleSwitch forEvent:(UIEvent *)event {
    assert([self.toggleSwitch isEqual:toggleSwitch]);

    if (self.toggleSwitch.isOn != self.behavior.isContinuous) {
        [self.delegate didChangeToggleSwitchStateForBehaviorCell:self];
    }
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setBehavior:(BLMBehavior *)behavior {
    assert([NSThread isMainThread]);
    
    if (self.behavior != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMBehaviorUpdatedNotification object:self.behavior];
    }

    _behavior = behavior;

    if (behavior != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBehaviorUpdated:) name:BLMBehaviorUpdatedNotification object:behavior];
    }
}


- (void)handleBehaviorUpdated:(NSNotification *)notification {
    BLMBehavior *updatedBehavior = notification.userInfo[BLMBehaviorNewBehaviorUserInfoKey];
    assert([BLMUtils isObject:updatedBehavior equalToObject:[[BLMDataManager sharedManager] behaviorForUUID:self.behavior.UUID]]);

    self.behavior = updatedBehavior;

    [self updateContent];
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

@interface BLMProjectDetailController () <UICollectionViewDataSource, ProjectDetailCollectionViewLayoutDelegate, BehaviorCellDelegate, BLMButtonCellDelegate>

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong) NSUUID *addedBehaviorUUID;

@end


@implementation BLMProjectDetailController

- (instancetype)initWithProject:(BLMProject *)project {
    assert(project != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUUID = project.UUID;

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Project Details";

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[ProjectDetailCollectionViewLayout alloc] init]];

    [self.collectionView registerClass:[SectionHeaderView class] forSupplementaryViewOfKind:HeaderKind withReuseIdentifier:NSStringFromClass([SectionHeaderView class])];
    [self.collectionView registerClass:[SectionSeparatorView class] forSupplementaryViewOfKind:SeparatorKind withReuseIdentifier:NSStringFromClass([SectionSeparatorView class])];
    [self.collectionView registerClass:[SectionBackgroundView class] forSupplementaryViewOfKind:ContentBackgroundKind withReuseIdentifier:NSStringFromClass([SectionBackgroundView class])];

    [self.collectionView registerClass:[BehaviorCell class] forCellWithReuseIdentifier:NSStringFromClass([BehaviorCell class])];
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

    BLMProject *project = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:project];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if (self.addedBehaviorUUID != nil) {
        BLMBehavior *addedBehavior = [[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID];
        NSUInteger cellItem = ([self.collectionView numberOfItemsInSection:ProjectDetailSectionBehaviors] - 2);

        if ([self isValidBehaviorName:addedBehavior.name forItem:cellItem]) {
            [self updateProjectDefaultSessionConfigurationByAddingBehaviorUUID:self.addedBehaviorUUID];
        } else {
            [[BLMDataManager sharedManager] deleteBehaviorForUUID:self.addedBehaviorUUID completion:nil];
        }
    }
}


- (BOOL)isValidBehaviorName:(NSString *)name forItem:(NSUInteger)item {
    NSString *lowercaseName = [name.lowercaseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (lowercaseName.length < BLMBehaviorNameMinimumLength) {
        return NO;
    }

    NSArray<NSUUID *> *behaviorUUIDs = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID].defaultSessionConfiguration.behaviorUUIDs;

    for (NSUInteger index = 0; index < behaviorUUIDs.count; index += 1) {
        if (index == item) {
            continue;
        }

        NSUUID *UUID = behaviorUUIDs[index];
        BLMBehavior *behavior = [[BLMDataManager sharedManager] behaviorForUUID:UUID];
        assert([behavior.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == behavior.name.length);

        if ([BLMUtils isString:lowercaseName equalToString:behavior.name.lowercaseString]) {
            return NO;
        }
    }

    return YES;
}


- (void)updateProjectDefaultSessionConfigurationByAddingBehaviorUUID:(NSUUID *)UUID {
    BLMProject *project = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID];
    NSArray<NSUUID *> *behaviorUUIDs = project.defaultSessionConfiguration.behaviorUUIDs;

    assert(UUID != nil);
    assert(![behaviorUUIDs containsObject:UUID]);

    NSDictionary *updatedSessionConfigurationValuesByProperty = @{ @(BLMSessionConfigurationPropertyBehaviorUUIDs):[behaviorUUIDs arrayByAddingObject:UUID] };
    BLMSessionConfiguration *updatedSessionConfiguration = [project.defaultSessionConfiguration copyWithUpdatedValuesByProperty:updatedSessionConfigurationValuesByProperty];

    [[BLMDataManager sharedManager] updateProjectForUUID:self.projectUUID property:BLMProjectPropertyDefaultSessionConfiguration value:updatedSessionConfiguration completion:nil];
}

#pragma mark Event Handling

- (void)handleProjectUpdated:(NSNotification *)notification {
    BLMProject *originalProject = (BLMProject *)notification.userInfo[BLMProjectOldProjectUserInfoKey];
    assert(originalProject == notification.object);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMProjectUpdatedNotification object:originalProject];

    BLMProject *updatedProject = (BLMProject *)notification.userInfo[BLMProjectNewProjectUserInfoKey];
    assert(updatedProject == [[BLMDataManager sharedManager] projectForUUID:self.projectUUID]);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:updatedProject];

    NSArray<NSUUID *> *endingBehaviorUUIDs = updatedProject.defaultSessionConfiguration.behaviorUUIDs;

    if (![BLMUtils isArray:originalProject.defaultSessionConfiguration.behaviorUUIDs equalToArray:endingBehaviorUUIDs]) {
        [self.collectionView performBatchUpdates:^{
            NSArray<NSUUID *> *startingBehaviorUUIDs = originalProject.defaultSessionConfiguration.behaviorUUIDs;
            NSMutableArray *deletedIndexPaths = [NSMutableArray array];

            NSMutableSet *deletedUUIDs = [NSMutableSet setWithArray:startingBehaviorUUIDs];
            [deletedUUIDs minusSet:[NSSet setWithArray:endingBehaviorUUIDs]];

            for (NSUUID *UUID in deletedUUIDs) {
                [deletedIndexPaths addObject:[NSIndexPath indexPathForItem:[startingBehaviorUUIDs indexOfObject:UUID] inSection:ProjectDetailSectionBehaviors]];
            }

            NSMutableSet<NSUUID *> *insertedUUIDs = [NSMutableSet setWithArray:endingBehaviorUUIDs];
            [insertedUUIDs minusSet:[NSMutableSet setWithArray:startingBehaviorUUIDs]];

            NSMutableArray *insertedIndexPaths = [NSMutableArray array];
            NSMutableArray *reloadIndexPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForItem:endingBehaviorUUIDs.count inSection:ProjectDetailSectionBehaviors]]; // Reload add behavior cell

            if ([insertedUUIDs containsObject:self.addedBehaviorUUID]) {
                [insertedUUIDs removeObject:self.addedBehaviorUUID];
                [reloadIndexPaths addObject:[NSIndexPath indexPathForItem:[endingBehaviorUUIDs indexOfObject:self.addedBehaviorUUID] inSection:ProjectDetailSectionBehaviors]];

                self.addedBehaviorUUID = nil;
            }

            for (NSUUID *UUID in insertedUUIDs) {
                [insertedIndexPaths addObject:[NSIndexPath indexPathForItem:[endingBehaviorUUIDs indexOfObject:UUID] inSection:ProjectDetailSectionBehaviors]];
            }

            [self.collectionView deleteItemsAtIndexPaths:deletedIndexPaths];
            [self.collectionView insertItemsAtIndexPaths:insertedIndexPaths];
            [self.collectionView reloadItemsAtIndexPaths:reloadIndexPaths];
        } completion:^(BOOL finished) {
            assert(finished);
        }];
    }
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
            numberOfItems = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID].defaultSessionConfiguration.behaviorUUIDs.count;

            if (self.addedBehaviorUUID != nil) {
                numberOfItems += 1; // +1 for the BLMBehavior that that's been added to the data model but not to a session configuration
            }

            numberOfItems += 1; // +1 for the "add behavior" button
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
            NSArray<NSUUID *> *behaviorUUIDs = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID].defaultSessionConfiguration.behaviorUUIDs;

            if ((indexPath.item < behaviorUUIDs.count) || ((indexPath.item == behaviorUUIDs.count) && (self.addedBehaviorUUID != nil))) {
                BehaviorCell *behaviorCell = (BehaviorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BehaviorCell class]) forIndexPath:indexPath];
                behaviorCell.delegate = self;

                NSUUID *behaviorUUID = ((indexPath.item < behaviorUUIDs.count) ? behaviorUUIDs[indexPath.item] : self.addedBehaviorUUID);
                behaviorCell.behavior = [[BLMDataManager sharedManager] behaviorForUUID:behaviorUUID];
                
                cell = behaviorCell;
            } else {
                assert((indexPath.item == (behaviorUUIDs.count + 1))
                       || ((indexPath.item == behaviorUUIDs.count)
                           && (self.addedBehaviorUUID == nil)));

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
    BLMProject *project = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID];

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
            NSArray<NSUUID *> *behaviorUUIDs = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID].defaultSessionConfiguration.behaviorUUIDs;

            assert((cell.item < behaviorUUIDs.count)
                   || ((cell.item == behaviorUUIDs.count)
                       && (self.addedBehaviorUUID != nil)));

            NSUUID *UUID = ((cell.item < behaviorUUIDs.count) ? behaviorUUIDs[cell.item] : self.addedBehaviorUUID);

            return [[BLMDataManager sharedManager] behaviorForUUID:UUID].name;
        }

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    assert(NO);
    return nil;
}


- (NSAttributedString *)attributedPlaceholderForTextInputCell:(BLMTextInputCell *)cell {
    NSString *placeholder = nil;
    NSDictionary *attributes = nil;
    
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo:
            placeholder = [NSString stringWithFormat:@"Required (%lu+ characters)", (unsigned long)[self minimumInputLengthForTextInputCell:cell]];
            attributes = [BLMTextInputCell errorAttributes];
            break;

        case ProjectDetailSectionSessionProperties:
            placeholder = @"Optional";
            break;

        case ProjectDetailSectionBehaviors:
            placeholder = [NSString stringWithFormat:@"Name (%lu+ characters)", (unsigned long)[self minimumInputLengthForTextInputCell:cell]];
            attributes = [BLMTextInputCell errorAttributes];
            break;

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            break;
        }
    }

    if (placeholder.length == 0) {
        assert(NO);
        return nil;
    }

    return [[NSAttributedString alloc] initWithString:placeholder attributes:attributes];
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
    return 0;
}


- (void)didChangeInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo:
            break;

        case ProjectDetailSectionSessionProperties:
            break;

        case ProjectDetailSectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            if (![BLMUtils isObject:behaviorCell.behavior.UUID equalToObject:self.addedBehaviorUUID]) {
                return;
            }

            NSString *originalName = behaviorCell.behavior.name;
            NSString *updatedName = cell.textField.text;

            if ([self isValidBehaviorName:originalName forItem:cell.item] != [self isValidBehaviorName:updatedName forItem:cell.item]) {
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:(cell.item + 1) inSection:ProjectDetailSectionBehaviors]]];
            }

            [[BLMDataManager sharedManager] updateBehaviorForUUID:self.addedBehaviorUUID property:BLMBehaviorPropertyName value:updatedName completion:nil];
            break;
        }

        case ProjectDetailSectionActionButtons:
            break;

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
            return [self isValidBehaviorName:cell.textField.text forItem:cell.item];
        }

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
}


- (void)didAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBasicInfo: {
            BLMProjectProperty updatedProjectProperty;

            switch ((BasicInfoSectionItem)cell.item) {
                case BasicInfoSectionItemProjectName:
                    updatedProjectProperty = BLMProjectPropertyName;
                    break;

                case BasicInfoSectionItemClientName:
                    updatedProjectProperty = BLMProjectPropertyClient;
                    break;

                case BasicInfoSectionItemCount: {
                    assert(NO);
                    break;
                }
            }

            [[BLMDataManager sharedManager] updateProjectForUUID:self.projectUUID property:updatedProjectProperty value:cell.textField.text completion:nil];
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

            BLMSessionConfiguration *originalSessionConfiguration = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID].defaultSessionConfiguration;
            BLMSessionConfiguration *updatedSessionConfiguration = [originalSessionConfiguration copyWithUpdatedValuesByProperty:@{ @(updatedSessionConfigurationProperty) : (cell.textField.text ?: @"") }];

            [[BLMDataManager sharedManager] updateProjectForUUID:self.projectUUID property:BLMProjectPropertyDefaultSessionConfiguration value:updatedSessionConfiguration completion:nil];
            break;
        }

        case ProjectDetailSectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            NSUUID *UUID = behaviorCell.behavior.UUID;

            assert([[BLMDataManager sharedManager] behaviorForUUID:UUID].isContinuous == behaviorCell.toggleSwitch.isOn);

            NSString *updatedName = cell.textField.text;
            assert([self isValidBehaviorName:updatedName forItem:cell.item]);

            [[BLMDataManager sharedManager] updateBehaviorForUUID:UUID property:BLMBehaviorPropertyName value:updatedName completion:nil];
            
            if ([BLMUtils isObject:UUID equalToObject:self.addedBehaviorUUID]) {
                [self updateProjectDefaultSessionConfigurationByAddingBehaviorUUID:UUID];
            }
            break;
        }

        case ProjectDetailSectionActionButtons:
        case ProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
}

#pragma mark BehaviorCellDelegate

- (void)didChangeToggleSwitchStateForBehaviorCell:(BehaviorCell *)cell {
    assert(cell.toggleSwitch.isOn != cell.behavior.isContinuous);
    
    [[BLMDataManager sharedManager] updateBehaviorForUUID:cell.behavior.UUID property:BLMBehaviorPropertyContinuous value:@(cell.toggleSwitch.isOn) completion:nil];
}

#pragma mark BLMButtonCellDelegate

- (BOOL)isButtonEnabledForButtonCell:(BLMButtonCell *)cell {
    switch ((ProjectDetailSection)cell.section) {
        case ProjectDetailSectionBehaviors: {
            assert(cell.item == ([self.collectionView numberOfItemsInSection:ProjectDetailSectionBehaviors] - 1));

            if (self.addedBehaviorUUID == nil) {
                return YES;
            }

            BehaviorCell *addedBehaviorCell = (BehaviorCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:(cell.item - 1) inSection:ProjectDetailSectionBehaviors]];

            return [self isValidBehaviorName:addedBehaviorCell.textField.text forItem:(cell.item - 1)];
        }

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
            assert(cell.item == ([self.collectionView numberOfItemsInSection:ProjectDetailSectionBehaviors] - 1));

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
            assert(cell.item == ([self.collectionView numberOfItemsInSection:ProjectDetailSectionBehaviors] - 1));

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
            assert(cell.item == ([self.collectionView numberOfItemsInSection:ProjectDetailSectionBehaviors] - 1));

            if (self.addedBehaviorUUID != nil) { // There is a valid behavior item that has not been officially added to the data model
                NSArray<NSUUID *> *behaviorUUIDs = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID].defaultSessionConfiguration.behaviorUUIDs;
                NSIndexPath *addedBehaviorIndexPath = [NSIndexPath indexPathForItem:behaviorUUIDs.count inSection:ProjectDetailSectionBehaviors];
                BehaviorCell *addedBehaviorCell = (BehaviorCell *)[self.collectionView cellForItemAtIndexPath:addedBehaviorIndexPath];

                assert([self isValidBehaviorName:addedBehaviorCell.textField.text forItem:behaviorUUIDs.count]);
                assert([BLMUtils isObject:[[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID] equalToObject:addedBehaviorCell.behavior]);
                assert(addedBehaviorCell.textField.isFirstResponder); // The "add behavior" must have been enabled in response to the added behavior cell's text becoming valid.

                [addedBehaviorCell.textField resignFirstResponder]; // Resign first responder to force update the data model
            }

            assert(self.addedBehaviorUUID == nil);

            [[BLMDataManager sharedManager] createBehaviorWithName:@"" continuous:NO completion:^(BLMBehavior *behavior, NSError *error) {
                if (error != nil) {
                    return;
                }

                self.addedBehaviorUUID = behavior.UUID;

                NSArray<NSUUID *> *behaviorUUIDs = [[BLMDataManager sharedManager] projectForUUID:self.projectUUID].defaultSessionConfiguration.behaviorUUIDs;
                NSIndexPath *addedBehaviorIndexPath = [NSIndexPath indexPathForItem:behaviorUUIDs.count inSection:ProjectDetailSectionBehaviors];

                [self.collectionView performBatchUpdates:^{
                    [self.collectionView insertItemsAtIndexPaths:@[addedBehaviorIndexPath]];
                } completion:^(BOOL finished) {
                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:(behaviorUUIDs.count + 1) inSection:ProjectDetailSectionBehaviors]]];
                    [self.collectionView scrollToItemAtIndexPath:addedBehaviorIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];

                    BehaviorCell *addedBehaviorCell = (BehaviorCell *)[self.collectionView cellForItemAtIndexPath:addedBehaviorIndexPath];
                    assert([BLMUtils isObject:[[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID] equalToObject:addedBehaviorCell.behavior]);

                    [addedBehaviorCell.textField becomeFirstResponder];

                    UITextRange *selectedTextRange = [addedBehaviorCell.textField textRangeFromPosition:addedBehaviorCell.textField.beginningOfDocument toPosition:addedBehaviorCell.textField.endOfDocument];
                    addedBehaviorCell.textField.selectedTextRange = selectedTextRange;
                }];
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
