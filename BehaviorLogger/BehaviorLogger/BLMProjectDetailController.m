//
//  BLMProjectDetailController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMBehavior.h"
#import "BLMButtonCell.h"
#import "BLMCollectionView.h"
#import "BLMDataManager.h"
#import "BLMProjectDetailController.h"
#import "BLMProjectMenuController.h"
#import "BLMTextInputCell.h"
#import "BLMTextField.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"
#import "NSArray+BLMAdditions.h"
#import "NSOrderedSet+BLMAdditions.h"


#pragma mark Constants

static CGFloat const SectionHeaderHeight = 30.0;
static UIEdgeInsets const SectionHeaderInsets = { .top = 0.0, .left = 10.0, .bottom = 10.0, .right = 20.0 };

static UIEdgeInsets const ItemAreaStandardInsets = { .top = 5.0, .left = 20.0, .bottom = 10.0, .right = 20.0 };

static CGFloat const SectionSeparatorHeight = 1.0;
static UIEdgeInsets const SectionSeparatorInsets = { .top = 10.0, .left = 20.0, .bottom = 0.0, .right = 20.0 };

static CGFloat const BehaviorCellDeleteButtonImageRadius = 12.0;
static CGFloat const BehaviorCellDeleteButtonOffset = ((2 * BehaviorCellDeleteButtonImageRadius) / 3.0);


typedef NS_ENUM(NSUInteger, Section) {
    SectionBasicProperties,
    SectionSessionProperties,
    SectionBehaviors,
    SectionSessions,
    SectionActionButtons,
    SectionCount
};


typedef NS_ENUM(NSUInteger, BasicInfo) {
    BasicInfoProjectName,
    BasicInfoClientName,
    BasicInfoCount
};


typedef NS_ENUM(NSUInteger, SessionConfigurationInfo) {
    SessionConfigurationInfoCondition,
    SessionConfigurationInfoLocation,
    SessionConfigurationInfoTherapist,
    SessionConfigurationInfoObserver,
    SessionConfigurationInfoCount
};


typedef NS_ENUM(NSUInteger, ActionButton) {
    ActionButtonDeleteProject,
    ActionButtonCount
};


#pragma mark

@interface BehaviorCellBackgroundView : UIView

@property (nonatomic, strong) UIColor *borderColor;

@end


@implementation BehaviorCellBackgroundView

- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeDarkBackground];

    _borderColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeBlue];

    return self;
}


- (void)setBorderColor:(UIColor *)borderColor {
    if ([BLMUtils isObject:self.borderColor equalToObject:borderColor]) {
        return;
    }

    _borderColor = borderColor;

    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    UIBezierPath *path = [UIBezierPath bezierPath];

    [path moveToPoint:(CGPoint) {
        .x = CGRectGetMinX(rect) + 0.5 + [BehaviorCellBackgroundView edgeLengthCoveredByDeleteButton],
        .y = CGRectGetMinY(rect) + 0.5
    }];

    [path addLineToPoint:(CGPoint) {
        .x = CGRectGetMaxX(rect) - 0.5 - BLMCollectionViewRoundedCornerRadius,
        .y = CGRectGetMinY(rect) + 0.5
    }];

    CGPoint arcCenter = (CGPoint) {
        .x = CGRectGetMaxX(rect) - 0.5 - BLMCollectionViewRoundedCornerRadius,
        .y = CGRectGetMinY(rect) + 0.5 + BLMCollectionViewRoundedCornerRadius
    };

    [path addArcWithCenter:arcCenter radius:BLMCollectionViewRoundedCornerRadius startAngle:(3 * M_PI_2) endAngle:0 clockwise:YES];

    [path addLineToPoint:(CGPoint) {
        .x = CGRectGetMaxX(rect) - 0.5,
        .y = CGRectGetMaxY(rect) - 0.5 - BLMCollectionViewRoundedCornerRadius
    }];

    arcCenter = (CGPoint) {
        .x = CGRectGetMaxX(rect) - 0.5 - BLMCollectionViewRoundedCornerRadius,
        .y = CGRectGetMaxY(rect) - 0.5 - BLMCollectionViewRoundedCornerRadius
    };

    [path addArcWithCenter:arcCenter radius:BLMCollectionViewRoundedCornerRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];

    [path addLineToPoint:(CGPoint) {
        .x = CGRectGetMinX(rect) + 0.5 + BLMCollectionViewRoundedCornerRadius,
        .y = CGRectGetMaxY(rect) - 0.5
    }];

    arcCenter = (CGPoint) {
        .x = CGRectGetMinX(rect) + 0.5 + BLMCollectionViewRoundedCornerRadius,
        .y = CGRectGetMaxY(rect) - 0.5 - BLMCollectionViewRoundedCornerRadius
    };

    [path addArcWithCenter:arcCenter radius:BLMCollectionViewRoundedCornerRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];

    [path addLineToPoint:(CGPoint) {
        .x = CGRectGetMinX(rect) + 0.5,
        .y = CGRectGetMinY(rect) + 0.5 + [BehaviorCellBackgroundView edgeLengthCoveredByDeleteButton]
    }];

    path.lineWidth = 1.0;

    [self.borderColor setStroke];

    [path stroke];
}


+ (CGFloat)edgeLengthCoveredByDeleteButton {
    static CGFloat coveredEdgeLength = 0;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        coveredEdgeLength = ceilf((BehaviorCellDeleteButtonImageRadius // The region in the top left corner that is covered by the delete button image circle...
                                   - BehaviorCellDeleteButtonOffset) // ...found by computing the horizontal distance between the circle's center and rect's left edge...
                                  + (BehaviorCellDeleteButtonImageRadius // ...added to horizontal the distance between the circle's center and the point of intersection with rect's top edge...
                                     * cos(asin((BehaviorCellDeleteButtonImageRadius // ...as determined from the angle between the circle's center and the intersection point...
                                                 - BehaviorCellDeleteButtonOffset) // ...given the vertical distance between the two...
                                                / BehaviorCellDeleteButtonImageRadius)))); // ...as a ratio of the circle's radius
    });

    return coveredEdgeLength;
}

@end


@class BehaviorCell;


@protocol BehaviorCellDelegate <BLMTextInputCellDelegate>

- (void)didFireDeleteButtonActionForBehaviorCell:(BehaviorCell *)cell;
- (void)didChangeToggleSwitchStateForBehaviorCell:(BehaviorCell *)cell;

@end


@interface BehaviorCell : BLMTextInputCell

@property (nonatomic, strong, readonly) UIButton *deleteButton;
@property (nonatomic, strong, readonly) UISwitch *toggleSwitch;
@property (nonatomic, strong, readonly) UILabel *toggleSwitchLabel;
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

    self.clipsToBounds = NO;
    self.backgroundView = [[BehaviorCellBackgroundView alloc] init];

    self.contentView.clipsToBounds = NO;
    self.contentView.backgroundColor = [self.backgroundView.backgroundColor colorWithAlphaComponent:0.0];

    // Delete Button

    static UIImage *deleteButtonDefaultImage = nil;
    static UIImage *deleteButtonSelectedImage = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        deleteButtonDefaultImage = [BLMViewUtils deleteItemImageWithBackgroundColor:[BLMViewUtils colorForHexCode:0x000000 alpha:0.6] diameter:(BehaviorCellDeleteButtonImageRadius * 2.0)];
        deleteButtonSelectedImage = [BLMViewUtils deleteItemImageWithBackgroundColor:[BLMViewUtils colorForHexCode:0xB83020 alpha:0.8] diameter:(BehaviorCellDeleteButtonImageRadius * 2.0)];
    });

    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];

    [self.deleteButton setImage:deleteButtonDefaultImage forState:UIControlStateNormal];
    [self.deleteButton setImage:deleteButtonSelectedImage forState:UIControlStateSelected];
    [self.deleteButton setImage:deleteButtonSelectedImage forState:UIControlStateHighlighted];

    [self.deleteButton addTarget:self action:@selector(handleActionForDeleteButton:forEvent:) forControlEvents:UIControlEventTouchUpInside];

    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.deleteButton];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.deleteButton attribute:NSLayoutAttributeLeft equalToItem:self.contentView constant:-BehaviorCellDeleteButtonOffset]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.deleteButton attribute:NSLayoutAttributeTop equalToItem:self.contentView constant:-BehaviorCellDeleteButtonOffset]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.deleteButton attribute:NSLayoutAttributeWidth equalToConstant:34.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.deleteButton attribute:NSLayoutAttributeHeight equalToConstant:34.0]];

    // Toggle Switch

    _toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];

    [self.toggleSwitch addTarget:self action:@selector(handleActionToggleSwitch:forEvent:) forControlEvents:UIControlEventTouchUpInside];

    self.toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.toggleSwitch];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.toggleSwitch attribute:NSLayoutAttributeTop equalToItem:self.textField attribute:NSLayoutAttributeBottom constant:10.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.toggleSwitch attribute:NSLayoutAttributeRight equalToItem:self.textField attribute:NSLayoutAttributeRight constant:-3.0]];

    // Toggle Switch Label

    _toggleSwitchLabel = [[UILabel alloc] init];

    [self.toggleSwitchLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.toggleSwitchLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self.toggleSwitchLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.toggleSwitchLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.toggleSwitchLabel.text = @"Continuous:";
    self.toggleSwitchLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.toggleSwitchLabel];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.toggleSwitchLabel attribute:NSLayoutAttributeCenterY equalToItem:self.toggleSwitch constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.toggleSwitchLabel attribute:NSLayoutAttributeLeft equalToItem:self.label constant:0.0]];

    return self;
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


- (void)updateContent {
    [super updateContent];
    [self updateBorderColor];

    self.toggleSwitch.on = self.behavior.isContinuous;
}


- (void)updateBorderColor {
    BehaviorCellBackgroundView *backgroundView = (BehaviorCellBackgroundView *)self.backgroundView;
    backgroundView.borderColor = ([self.delegate shouldAcceptInputForTextInputCell:self] ? [BLMViewUtils colorForHexCode:BLMColorHexCodeBlue] : [BLMCollectionViewCell errorColor]);
}


- (void)handleActionForDeleteButton:(UIButton *)deleteButton forEvent:(UIEvent *)event {
    assert([BLMUtils isObject:deleteButton equalToObject:self.deleteButton]);
    [self.delegate didFireDeleteButtonActionForBehaviorCell:self];
}


- (void)handleActionToggleSwitch:(UISwitch *)toggleSwitch forEvent:(UIEvent *)event {
    assert([BLMUtils isObject:toggleSwitch equalToObject:self.toggleSwitch]);
    if (self.toggleSwitch.isOn != self.behavior.isContinuous) {
        [self.delegate didChangeToggleSwitchStateForBehaviorCell:self];
    }
}


- (void)handleBehaviorUpdated:(NSNotification *)notification {
    BLMBehavior *updatedBehavior = notification.userInfo[BLMBehaviorUpdatedBehaviorUserInfoKey];
    assert([BLMUtils isObject:updatedBehavior equalToObject:[[BLMDataManager sharedManager] behaviorForUUID:self.behavior.UUID]]);

    self.behavior = updatedBehavior;

    [self updateContent];
}


- (void)updateLabelSubviewsPreferredMaxLayoutWidthWithLayoutRequired:(BOOL *)layoutRequired {
    [super updateLabelSubviewsPreferredMaxLayoutWidthWithLayoutRequired:layoutRequired];

    CGFloat preferredMaxLayoutWidth = CGRectGetWidth([self.toggleSwitchLabel alignmentRectForFrame:self.toggleSwitchLabel.frame]);

    if (preferredMaxLayoutWidth != self.toggleSwitchLabel.preferredMaxLayoutWidth) {
        self.toggleSwitchLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
        *layoutRequired = YES;
    }
}

#pragma mark BLMCollectionViewCellLayoutDelegate

- (NSArray<NSLayoutConstraint *> *)uniqueVerticalPositionConstraintsForSubview:(UIView *)subview {
    NSMutableArray *constraints = [NSMutableArray array];

    if ([BLMUtils isObject:subview equalToObject:self.label]) {
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeTop equalToItem:self.contentView constant:25.0]];
    } else if ([BLMUtils isObject:subview equalToObject:self.textField]) {
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeBaseline equalToItem:self.label constant:0.0]];
    }

    return constraints;
}


- (NSArray<NSLayoutConstraint *> *)uniqueHorizontalPositionConstraintsForSubview:(UIView *)subview {
    NSMutableArray *constraints = [NSMutableArray array];

    if ([BLMUtils isObject:subview equalToObject:self.label]) {
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeLeft equalToItem:self.contentView constant:8.0]];
    } else if ([BLMUtils isObject:subview equalToObject:self.textField]) {
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeRight equalToItem:self.contentView constant:-8.0]];
        [constraints addObject:[BLMViewUtils constraintWithItem:subview attribute:NSLayoutAttributeLeft equalToItem:self.label attribute:NSLayoutAttributeRight constant:5.0]];
    }

    return constraints;
}

@end


#pragma mark

@interface BLMProjectDetailController () <UICollectionViewDataSource, BLMCollectionViewLayoutDelegate, BLMTextInputCellDataSource, BehaviorCellDelegate, BLMButtonCellDataSource, BLMButtonCellDelegate>

@property (nonatomic, strong, readonly) BLMCollectionView *collectionView;
@property (nonatomic, strong, readonly) UILabel *instructionsLabel;
@property (nonatomic, assign, readonly) NSRange instructionsLabelClickableRange;
@property (nonatomic, strong) NSUUID *addedBehaviorUUID;

@end


@implementation BLMProjectDetailController

- (instancetype)initWithProjectUUID:(NSUUID *)projectUUID delegate:(id<BLMProjectDetailControllerDelegate>)delegate {
    assert(delegate != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUUID = projectUUID;
    _delegate = delegate;

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Project Details";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeDefaultBackground];

    if (self.projectUUID == nil) {
        _instructionsLabel = [[UILabel alloc] init];

        [self.instructionsLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.instructionsLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        [self.instructionsLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [self.instructionsLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        [self.instructionsLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleInstructionsLabelTapGestureRecognizer:)]];

        NSString *unclickablePrefix = @"Select an existing project to view details about it, or\nstart a new one with the \"";
        NSString *unclickableSuffix = @"\" menu item.";
        NSString *instructions = [NSString stringWithFormat:@"%@%@%@", unclickablePrefix, BLMCreateProjectCellText, unclickableSuffix];

        _instructionsLabelClickableRange = (NSRange){
            .location = unclickablePrefix.length,
            .length = (instructions.length - unclickablePrefix.length - unclickableSuffix.length)
        };

        assert(self.instructionsLabelClickableRange.length == BLMCreateProjectCellText.length);
        assert(NSEqualRanges(self.instructionsLabelClickableRange, [instructions rangeOfString:BLMCreateProjectCellText]));

        NSDictionary *defaultAttributes = @{ NSFontAttributeName:[UIFont systemFontOfSize:30.0], NSParagraphStyleAttributeName:[BLMViewUtils centerAlignedParagraphStyle] };
        NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc] initWithString:instructions attributes:defaultAttributes];

        [labelText addAttributes:@{ NSForegroundColorAttributeName:[BLMViewUtils colorForHexCode:BLMCreateProjectCellTextColor], NSUnderlineStyleAttributeName:@YES } range:self.instructionsLabelClickableRange];

        self.instructionsLabel.attributedText = labelText;
        self.instructionsLabel.numberOfLines = 0;
        self.instructionsLabel.userInteractionEnabled = YES;
        self.instructionsLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [self.view addSubview:self.instructionsLabel];
        [self.view addConstraints:[BLMViewUtils constraintsForItem:self.instructionsLabel centeredOnItem:self.view]];
    } else {
        _collectionView = [[BLMCollectionView alloc] initWithFrame:CGRectZero];

        [self.collectionView registerClass:[BLMSectionHeaderView class] forSupplementaryViewOfKind:BLMCollectionViewKindHeader withReuseIdentifier:NSStringFromClass([BLMSectionHeaderView class])];
        [self.collectionView registerClass:[BLMSectionSeparatorFooterView class] forSupplementaryViewOfKind:BLMCollectionViewKindFooter withReuseIdentifier:NSStringFromClass([BLMSectionSeparatorFooterView class])];
        [self.collectionView registerClass:[BLMItemAreaBackgroundView class] forSupplementaryViewOfKind:BLMCollectionViewKindItemAreaBackground withReuseIdentifier:NSStringFromClass([BLMItemAreaBackgroundView class])];

        [self.collectionView registerClass:[BehaviorCell class] forCellWithReuseIdentifier:NSStringFromClass([BehaviorCell class])];
        [self.collectionView registerClass:[BLMTextInputCell class] forCellWithReuseIdentifier:NSStringFromClass([BLMTextInputCell class])];
        [self.collectionView registerClass:[BLMButtonCell class] forCellWithReuseIdentifier:NSStringFromClass([BLMButtonCell class])];

        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.collectionView.scrollEnabled = YES;
        self.collectionView.bounces = YES;
        self.collectionView.backgroundColor = self.view.backgroundColor;
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;

        [self.view addSubview:self.collectionView];
        [self.view addConstraints:[BLMViewUtils constraintsForItem:self.collectionView equalToItem:self.view]];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:self.project];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionConfigurationUpdated:) name:BLMSessionConfigurationUpdatedNotification object:self.projectSessionConfiguration];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBehaviorUpdated:) name:BLMBehaviorUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBehaviorDeleted:) name:BLMBehaviorDeletedNotification object:nil];
    }
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if (self.addedBehaviorUUID != nil) {
        BLMBehavior *addedBehavior = [[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID];

        if ([self isBehaviorName:addedBehavior.name validForUUID:self.addedBehaviorUUID]) {
            [self updateProjectSessionConfigurationWithAddedBehaviorUUID];
        } else {
            [[BLMDataManager sharedManager] deleteBehaviorForUUID:self.addedBehaviorUUID completion:nil];
        }
    }
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (self.instructionsLabel != nil) {
        assert(self.projectUUID == nil);

        self.instructionsLabel.preferredMaxLayoutWidth = CGRectGetWidth([self.instructionsLabel alignmentRectForFrame:self.instructionsLabel.frame]);

        [self.view layoutIfNeeded];
    }
}

#pragma mark Utility

- (BLMProject *)project {
    return [[BLMDataManager sharedManager] projectForUUID:self.projectUUID];
}


- (BLMSessionConfiguration *)projectSessionConfiguration {
    return [[BLMDataManager sharedManager] sessionConfigurationForUUID:self.project.sessionConfigurationUUID];
}


- (BOOL)isBehaviorName:(NSString *)name validForUUID:(NSUUID *)UUID {
    NSString *lowercaseName = [name.lowercaseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (lowercaseName.length < BLMBehaviorNameMinimumLength) {
        return NO;
    }

    for (BLMBehavior *behavior in [NSEnumerator behaviorEnumeratorForUUIDs:self.projectSessionConfiguration.behaviorUUIDs dataManager:[BLMDataManager sharedManager]]) {
        if (![BLMUtils isObject:behavior.UUID equalToObject:UUID] && [BLMUtils isString:lowercaseName equalToString:behavior.name.lowercaseString]) {
            return NO;
        }
    }

    return YES;
}


- (void)updateProjectSessionConfigurationWithAddedBehaviorUUID {
    assert(self.addedBehaviorUUID != nil);
    assert(![self.projectSessionConfiguration.behaviorUUIDs containsObject:self.addedBehaviorUUID]);
    assert([self isBehaviorName:[[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID].name validForUUID:self.addedBehaviorUUID]);

    BLMSessionConfiguration *sessionConfiguration = self.projectSessionConfiguration;
    NSOrderedSet *updatedBehaviorUUIDs = [sessionConfiguration.behaviorUUIDs orderedSetByAddingObject:self.addedBehaviorUUID];

    [[BLMDataManager sharedManager] updateSessionConfigurationForUUID:sessionConfiguration.UUID property:BLMSessionConfigurationPropertyBehaviorUUIDs value:updatedBehaviorUUIDs completion:nil];

    assert(self.addedBehaviorUUID == nil);
}


- (NSIndexPath *)indexPathForAddBehaviorButtonCell {
    NSUInteger cellItem = ([self.collectionView numberOfItemsInSection:SectionBehaviors] - 1);
    return [NSIndexPath indexPathForItem:cellItem inSection:SectionBehaviors];
}


- (NSIndexPath *)indexPathForCreateSessionButtonCell {
    NSUInteger cellItem = ([self.collectionView numberOfItemsInSection:SectionSessions] - 1);
    return [NSIndexPath indexPathForItem:cellItem inSection:SectionSessions];
}

#pragma mark Event Handling

- (void)handleProjectUpdated:(NSNotification *)notification {
    BLMProject *original = (BLMProject *)notification.userInfo[BLMProjectOriginalProjectUserInfoKey];
    assert(original == notification.object);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMProjectUpdatedNotification object:original];

    BLMProject *updated = (BLMProject *)notification.userInfo[BLMProjectUpdatedProjectUserInfoKey];
    assert(updated == self.project);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:updated];

    if (![BLMUtils isObject:original.sessionConfigurationUUID equalToObject:updated.sessionConfigurationUUID]) {
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:SectionBehaviors]];
    }
}


- (void)handleSessionConfigurationUpdated:(NSNotification *)notification {
    BLMSessionConfiguration *original = (BLMSessionConfiguration *)notification.userInfo[BLMSessionConfigurationOriginalSessionConfigurationUserInfoKey];
    assert(original == notification.object);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMSessionConfigurationUpdatedNotification object:original];

    BLMSessionConfiguration *updated = (BLMSessionConfiguration *)notification.userInfo[BLMSessionConfigurationUpdatedSessionConfigurationUserInfoKey];
    assert(updated == self.projectSessionConfiguration);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionConfigurationUpdated:) name:BLMSessionConfigurationUpdatedNotification object:updated];

    if ([BLMUtils isOrderedSet:original.behaviorUUIDs equalToOrderedSet:updated.behaviorUUIDs]) {
        return;
    }

    [self.collectionView performBatchUpdates:^{
        NSMutableArray<NSIndexPath *> *reloadedIndexPaths = [NSMutableArray arrayWithObject:[self indexPathForAddBehaviorButtonCell]];
        NSMutableArray<NSIndexPath *> *deletedIndexPaths = [NSMutableArray array];

        [original.behaviorUUIDs enumerateObjectsUsingBlock:^(NSUUID *__nonnull UUID, NSUInteger index, BOOL *__nonnull stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:SectionBehaviors];

            if ([updated.behaviorUUIDs containsObject:UUID]) {
                [reloadedIndexPaths addObject:indexPath];
            } else {
                [deletedIndexPaths addObject:indexPath];
            }
        }];

        NSUInteger addedBehaviorUUIDIndex = [updated.behaviorUUIDs indexOfObject:self.addedBehaviorUUID];

        if (addedBehaviorUUIDIndex != NSNotFound) {
            [reloadedIndexPaths addObject:[NSIndexPath indexPathForItem:addedBehaviorUUIDIndex inSection:SectionBehaviors]];
            self.addedBehaviorUUID = nil;
        }

        NSMutableArray<NSIndexPath *> *insertedIndexPaths = [NSMutableArray array];

        [updated.behaviorUUIDs enumerateObjectsUsingBlock:^(NSUUID *__nonnull UUID, NSUInteger index, BOOL *__nonnull stop) {
            if ((index != addedBehaviorUUIDIndex) && ![original.behaviorUUIDs containsObject:UUID]) {
                [insertedIndexPaths addObject:[NSIndexPath indexPathForItem:index inSection:SectionBehaviors]];
            }
        }];

        [self.collectionView deleteItemsAtIndexPaths:deletedIndexPaths];
        [self.collectionView insertItemsAtIndexPaths:insertedIndexPaths];
        [self.collectionView reloadItemsAtIndexPaths:reloadedIndexPaths];
    } completion:^(BOOL finished) {
        assert(finished);
    }];
}


- (void)handleBehaviorUpdated:(NSNotification *)notification {
    BLMBehavior *behavior = (BLMBehavior *)notification.object;
    BOOL updatedBehaviorIsAddedBehavior = [BLMUtils isObject:behavior.UUID equalToObject:self.addedBehaviorUUID];
    NSOrderedSet<NSUUID *> *behaviorUUIDs = self.projectSessionConfiguration.behaviorUUIDs;

    if ((self.addedBehaviorUUID == nil)
        || (!updatedBehaviorIsAddedBehavior
            && ![behaviorUUIDs containsObject:behavior.UUID])) { // Currently only interested in updates that impact the added behavior's validity so we know when to reload the add behavior button cell
        return;
    }

    BLMBehavior *addedBehavior = [[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID];
    BOOL isAddedBehaviorNameValid = [self isBehaviorName:addedBehavior.name validForUUID:self.addedBehaviorUUID];
    BOOL wasAddedBehaviorNameValid = NO; // The added behavior name must have been invalid the last time its cell lost focus, otherwise its UUID would be in the project's default session configuration

    if (updatedBehaviorIsAddedBehavior) {
        wasAddedBehaviorNameValid = [self isBehaviorName:behavior.name validForUUID:self.addedBehaviorUUID];
    }

    if (wasAddedBehaviorNameValid == isAddedBehaviorNameValid) { // Reload only when the validity of the added behavior's name changes to avoid strobing of the add behavior button cell image
        return;
    }

    if (updatedBehaviorIsAddedBehavior) { // Enable the add behavior button cell, but don't reload the added behavior cell or it will lose its first responder status; its own notification handler will update its UI
        [self.collectionView reloadItemsAtIndexPaths:@[[self indexPathForAddBehaviorButtonCell]]];
    } else if (isAddedBehaviorNameValid) {
        [self updateProjectSessionConfigurationWithAddedBehaviorUUID];
    }
}


- (void)handleBehaviorDeleted:(NSNotification *)notification {
    BLMBehavior *behavior = (BLMBehavior *)notification.object;
    BLMSessionConfiguration *sessionConfiguration = self.projectSessionConfiguration;
    NSOrderedSet<NSUUID *> *behaviorUUIDs = sessionConfiguration.behaviorUUIDs;

    if ([BLMUtils isObject:behavior.UUID equalToObject:self.addedBehaviorUUID]) {
        assert(![behaviorUUIDs containsObject:self.addedBehaviorUUID]);

        self.addedBehaviorUUID = nil;

        [self.collectionView performBatchUpdates:^{
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:behaviorUUIDs.count inSection:SectionBehaviors]]];
            [self.collectionView reloadItemsAtIndexPaths:@[[self indexPathForAddBehaviorButtonCell]]];
        } completion:^(BOOL finished) {
            assert(finished);
        }];
    } else if ([behaviorUUIDs containsObject:behavior.UUID]) {
        NSOrderedSet<NSUUID *> *updatedBehaviorUUIDs = [behaviorUUIDs orderedSetByRemovingObject:behavior.UUID];
        [[BLMDataManager sharedManager] updateSessionConfigurationForUUID:sessionConfiguration.UUID property:BLMSessionConfigurationPropertyBehaviorUUIDs value:updatedBehaviorUUIDs completion:nil];
    }
}


- (void)handleInstructionsLabelTapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer {
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:self.instructionsLabel.bounds.size];
    textContainer.lineBreakMode = self.instructionsLabel.lineBreakMode;
    textContainer.lineFragmentPadding = 0;

    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];

    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.instructionsLabel.attributedText];
    [textStorage addLayoutManager:layoutManager]; // Sends -[NSLayoutManager setTextStorage:] to aLayoutManager with the receiver.

    NSRange glyphRange;
    [layoutManager characterRangeForGlyphRange:self.instructionsLabelClickableRange actualGlyphRange:&glyphRange]; // Convert the range for glyphs.

    CGRect clickableTextFrame = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];

    if (CGRectContainsPoint(clickableTextFrame, [tapGestureRecognizer locationInView:self.instructionsLabel])) {
        [self.delegate projectDetailControllerDidInitiateProjectCreation:self];
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return SectionCount;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch ((Section)section) {
        case SectionBasicProperties:
            return BasicInfoCount;

        case SectionSessionProperties:
            return SessionConfigurationInfoCount;

        case SectionBehaviors: {
            NSInteger itemCount = self.projectSessionConfiguration.behaviorUUIDs.count;

            if (self.addedBehaviorUUID != nil) {
                itemCount += 1; // +1 for the BLMBehavior that's been added to the data model but not to a session configuration
            }

            return (itemCount + 1); // +1 for the "add behavior" button cell
        }

        case SectionSessions:
            return (self.project.sessionUUIDs.count + 1); // +1 for the "begin session" button cell

        case SectionActionButtons:
            return ActionButtonCount;

        case SectionCount: {
            assert(NO);
            return 0;
        }
    }
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BLMCollectionViewCell *cell = nil;

    switch ((Section)indexPath.section) {
        case SectionBasicProperties:
        case SectionSessionProperties: {
            BLMTextInputCell *textInputCell = (BLMTextInputCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMTextInputCell class]) forIndexPath:indexPath];
            textInputCell.dataSource = self;
            textInputCell.delegate = self;

            cell = textInputCell;
            break;
        }

        case SectionBehaviors: {
            NSOrderedSet<NSUUID *> *behaviorUUIDs = self.projectSessionConfiguration.behaviorUUIDs;

            if ((indexPath.item < behaviorUUIDs.count) || ((indexPath.item == behaviorUUIDs.count) && (self.addedBehaviorUUID != nil))) {
                BehaviorCell *behaviorCell = (BehaviorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BehaviorCell class]) forIndexPath:indexPath];
                behaviorCell.dataSource = self;
                behaviorCell.delegate = self;

                NSUUID *behaviorUUID = ((indexPath.item < behaviorUUIDs.count) ? behaviorUUIDs[indexPath.item] : self.addedBehaviorUUID);
                behaviorCell.behavior = [[BLMDataManager sharedManager] behaviorForUUID:behaviorUUID];
                
                cell = behaviorCell;
            } else {
                assert((indexPath.item == (behaviorUUIDs.count + 1))
                       || ((indexPath.item == behaviorUUIDs.count)
                           && (self.addedBehaviorUUID == nil)));

                BLMButtonCell *buttonCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMButtonCell class]) forIndexPath:indexPath];
                buttonCell.dataSource = self;
                buttonCell.delegate = self;

                cell = buttonCell;
            }

            break;
        }

        case SectionSessions:
        case SectionActionButtons: {
            BLMButtonCell *buttonCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMButtonCell class]) forIndexPath:indexPath];
            buttonCell.dataSource = self;
            buttonCell.delegate = self;

            cell = buttonCell;
            break;
        }

        case SectionCount: {
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

    if ([BLMUtils isString:kind equalToString:BLMCollectionViewKindHeader]) {
        BLMSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([BLMSectionHeaderView class]) forIndexPath:indexPath];

        view = headerView;

        switch ((Section)indexPath.section) {
            case SectionSessionProperties: {
                headerView.label.text = @"Default Session Properties";
                break;
            }

            case SectionBehaviors: {
                headerView.label.text = @"Behaviors";
                break;
            }

            case SectionSessions: {
                headerView.label.text = @"Sessions";
                break;
            }

            case SectionBasicProperties:
            case SectionActionButtons:
            case SectionCount: {
                assert(NO);
                break;
            }
        }
    } else if ([BLMUtils isString:kind equalToString:BLMCollectionViewKindFooter]) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([BLMSectionSeparatorFooterView class]) forIndexPath:indexPath];
    } else if ([BLMUtils isString:kind equalToString:BLMCollectionViewKindItemAreaBackground]) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([BLMItemAreaBackgroundView class]) forIndexPath:indexPath];
    }

    return view;
}

#pragma mark UICollectionViewDelegate / BLMCollectionViewLayoutDelegate

- (BLMCollectionViewSectionLayout)collectionView:(BLMCollectionView *)collectionView layoutForSection:(NSUInteger)section {
    switch ((Section)section) {
        case SectionBasicProperties: {
            return (BLMCollectionViewSectionLayout) {
                .Header = {
                    .Height = 0.0,
                    .Insets = UIEdgeInsetsZero
                },
                .ItemArea = {
                    .HasBackground = NO,
                    .Insets = {
                        .top = 20.0,
                        .left = 20.0,
                        .bottom = 10.0,
                        .right = 20.0
                    },
                    .Grid = {
                        .ColumnCount = 2,
                        .ColumnSpacing = 20.0,
                        .RowSpacing = 0.0,
                        .RowHeight = 40.0,
                        .Insets = UIEdgeInsetsZero
                    }
                },
                .Footer = {
                    .Height = 0.0,
                    .Insets = UIEdgeInsetsZero
                }
            };
        }

        case SectionSessionProperties: {
            return (BLMCollectionViewSectionLayout) {
                .Header = {
                    .Height = SectionHeaderHeight,
                    .Insets = SectionHeaderInsets
                },
                .ItemArea = {
                    .HasBackground = NO,
                    .Insets = ItemAreaStandardInsets,
                    .Grid = {
                        .ColumnCount = 2,
                        .ColumnSpacing = 20.0,
                        .RowSpacing = 10.0,
                        .RowHeight = 40.0,
                        .Insets = UIEdgeInsetsZero
                    }
                },
                .Footer = {
                    .Height = 0.0,
                    .Insets = UIEdgeInsetsZero
                }
            };
        }

        case SectionBehaviors: {
            return (BLMCollectionViewSectionLayout) {
                .Header = {
                    .Height = SectionHeaderHeight,
                    .Insets = SectionHeaderInsets
                },
                .ItemArea = {
                    .HasBackground = YES,
                    .Insets = ItemAreaStandardInsets,
                    .Grid = {
                        .ColumnCount = 4,
                        .ColumnSpacing = 12.0,
                        .RowSpacing = 10.0,
                        .RowHeight = 105.0,
                        .Insets = {
                            .top = 10.0,
                            .left = 10.0,
                            .bottom = 10.0,
                            .right = 10.0
                        }
                    }
                },
                .Footer = {
                    .Height = 0.0,
                    .Insets = UIEdgeInsetsZero
                }
            };
        }

        case SectionSessions: {
            return (BLMCollectionViewSectionLayout) {
                .Header = {
                    .Height = SectionHeaderHeight,
                    .Insets = SectionHeaderInsets
                },
                .ItemArea = {
                    .HasBackground = YES,
                    .Insets = ItemAreaStandardInsets,
                    .Grid = {
                        .ColumnCount = 1,
                        .ColumnSpacing = 0.0,
                        .RowSpacing = 10.0,
                        .RowHeight = 40.0,
                        .Insets = {
                            .top = 10.0,
                            .left = 10.0,
                            .bottom = 10.0,
                            .right = 10.0
                        }
                    }
                },
                .Footer = {
                    .Height = SectionSeparatorHeight,
                    .Insets = SectionSeparatorInsets
                }
            };
        }

        case SectionActionButtons: {
            return (BLMCollectionViewSectionLayout) {
                .Header = {
                    .Height = 0.0,
                    .Insets = UIEdgeInsetsZero
                },
                .ItemArea = {
                    .HasBackground = NO,
                    .Insets = ItemAreaStandardInsets,
                    .Grid = {
                        .ColumnCount = ActionButtonCount,
                        .ColumnSpacing = 0.0,
                        .RowSpacing = 10.0,
                        .RowHeight = 40.0,
                        .Insets = UIEdgeInsetsZero
                    }
                },
                .Footer = {
                    .Height = 0.0,
                    .Insets = UIEdgeInsetsZero
                }
            };
        }

        case SectionCount: {
            assert(NO);
            return BLMCollectionViewSectionLayoutNull;
        }
    }
}

#pragma mark BLMTextInputCellDataSource

- (NSString *)labelForTextInputCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionBasicProperties: {
            switch ((BasicInfo)cell.item) {
                case BasicInfoProjectName:
                    return @"Project:";

                case BasicInfoClientName:
                    return @"Client:";

                case BasicInfoCount: {
                    assert(NO);
                    return nil;
                }
            }
        }

        case SectionSessionProperties: {
            switch ((SessionConfigurationInfo)cell.item) {
                case SessionConfigurationInfoCondition:
                    return @"Condition:";

                case SessionConfigurationInfoLocation:
                    return @"Location:";

                case SessionConfigurationInfoTherapist:
                    return @"Therapist:";

                case SessionConfigurationInfoObserver:
                    return @"Observer:";

                case SessionConfigurationInfoCount: {
                    assert(NO);
                    return nil;
                }
            }
        }

        case SectionBehaviors:
            return @"Name:";

        case SectionSessions:
        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return nil;
        }
    }
}


- (NSString *)defaultInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionBasicProperties: {
            switch ((BasicInfo)cell.item) {
                case BasicInfoProjectName:
                    return self.project.name;

                case BasicInfoClientName:
                    return self.project.client;

                case BasicInfoCount: {
                    assert(NO);
                    return nil;
                }
            }
        }

        case SectionSessionProperties: {
            switch ((SessionConfigurationInfo)cell.item) {
                case SessionConfigurationInfoCondition:
                    return self.projectSessionConfiguration.condition;

                case SessionConfigurationInfoLocation:
                    return self.projectSessionConfiguration.location;

                case SessionConfigurationInfoTherapist:
                    return self.projectSessionConfiguration.therapist;

                case SessionConfigurationInfoObserver:
                    return self.projectSessionConfiguration.observer;

                case SessionConfigurationInfoCount: {
                    assert(NO);
                    return nil;
                }
            }
        }

        case SectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            NSUUID *UUID = behaviorCell.behavior.UUID;

            return [[BLMDataManager sharedManager] behaviorForUUID:UUID].name;
        }

        case SectionSessions:
        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return nil;
        }
    }
}


- (NSAttributedString *)attributedPlaceholderForTextInputCell:(BLMTextInputCell *)cell {
    NSString *placeholder = nil;
    NSDictionary *attributes = nil;
    
    switch ((Section)cell.section) {
        case SectionBasicProperties:
            placeholder = [NSString stringWithFormat:@"Required (%tu+ characters)", [self minimumInputLengthForTextInputCell:cell]];
            attributes = [BLMTextInputCell errorAttributes];
            break;

        case SectionSessionProperties:
            placeholder = @"Optional";
            break;

        case SectionBehaviors:
            placeholder = [NSString stringWithFormat:@"%tu+ characters", [self minimumInputLengthForTextInputCell:cell]];
            attributes = [BLMTextInputCell errorAttributes];
            break;

        case SectionSessions:
        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return nil;
        }
    }

    assert(placeholder.length > 0);
    return [[NSAttributedString alloc] initWithString:placeholder attributes:attributes];
}


- (NSUInteger)minimumInputLengthForTextInputCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionBasicProperties: {
            switch ((BasicInfo)cell.item) {
                case BasicInfoProjectName:
                    return BLMProjectNameMinimumLength;

                case BasicInfoClientName:
                    return BLMProjectClientMinimumLength;

                case BasicInfoCount: {
                    assert(NO);
                    return 0;
                }
            }
        }

        case SectionSessionProperties:
            return 0;

        case SectionBehaviors:
            return BLMBehaviorNameMinimumLength;

        case SectionSessions:
        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return 0;
        }
    }
}

#pragma mark BehaviorCellDelegate / BLMTextInputCellDelegate

- (void)didChangeInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            NSUUID *UUID = behaviorCell.behavior.UUID;

            if ([BLMUtils isObject:UUID equalToObject:self.addedBehaviorUUID]) { // Update the added behavior on every cell text change, but ignore established behaviors' cells until they call didAcceptInputForTextInputCell:
                [[BLMDataManager sharedManager] updateBehaviorForUUID:UUID property:BLMBehaviorPropertyName value:cell.textField.text completion:nil];
            }

            [behaviorCell updateBorderColor];
            break;
        }

        case SectionBasicProperties:
        case SectionSessionProperties:
            break;

        case SectionSessions:
        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            break;
        }
    }
}


- (BOOL)shouldAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionBasicProperties: {
            switch ((BasicInfo)cell.item) {
                case BasicInfoProjectName: {
                    if ([[BLMDataManager sharedManager].projectNameSet containsObject:cell.textField.text] && ![BLMUtils isString:cell.textField.text equalToString:self.project.name]) {
                        return NO;
                    }
                }

                case BasicInfoClientName:
                    return (cell.textField.text.length >= [self minimumInputLengthForTextInputCell:cell]);

                case BasicInfoCount: {
                    assert(NO);
                    return NO;
                }
            }
        }

        case SectionSessionProperties:
            return YES;

        case SectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            return [self isBehaviorName:cell.textField.text validForUUID:behaviorCell.behavior.UUID];
        }

        case SectionSessions:
        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return NO;
        }
    }
}


- (void)didAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionBasicProperties: {
            BLMProjectProperty updatedProperty;

            switch ((BasicInfo)cell.item) {
                case BasicInfoProjectName:
                    updatedProperty = BLMProjectPropertyName;
                    break;

                case BasicInfoClientName:
                    updatedProperty = BLMProjectPropertyClient;
                    break;

                case BasicInfoCount: {
                    assert(NO);
                    break;
                }
            }

            [[BLMDataManager sharedManager] updateProjectForUUID:self.projectUUID property:updatedProperty value:cell.textField.text completion:nil];
            break;
        }

        case SectionSessionProperties: {
            BLMSessionConfigurationProperty updatedProperty;

            switch ((SessionConfigurationInfo)cell.item) {
                case SessionConfigurationInfoCondition:
                    updatedProperty = BLMSessionConfigurationPropertyCondition;
                    break;

                case SessionConfigurationInfoLocation:
                    updatedProperty = BLMSessionConfigurationPropertyLocation;
                    break;

                case SessionConfigurationInfoTherapist:
                    updatedProperty = BLMSessionConfigurationPropertyTherapist;
                    break;

                case SessionConfigurationInfoObserver:
                    updatedProperty = BLMSessionConfigurationPropertyObserver;
                    break;

                case SessionConfigurationInfoCount: {
                    assert(NO);
                    break;
                }
            }

            [[BLMDataManager sharedManager] updateSessionConfigurationForUUID:self.project.sessionConfigurationUUID property:updatedProperty value:cell.textField.text completion:nil];
            break;
        }

        case SectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            NSUUID *UUID = behaviorCell.behavior.UUID;

            assert([[BLMDataManager sharedManager] behaviorForUUID:UUID].isContinuous == behaviorCell.toggleSwitch.isOn);

            NSString *updatedName = cell.textField.text;
            assert([self isBehaviorName:updatedName validForUUID:UUID]);

            [[BLMDataManager sharedManager] updateBehaviorForUUID:UUID property:BLMBehaviorPropertyName value:updatedName completion:nil];
            
            if ([BLMUtils isObject:UUID equalToObject:self.addedBehaviorUUID]) {
                [self updateProjectSessionConfigurationWithAddedBehaviorUUID];
            }
            break;
        }

        case SectionSessions:
        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            break;
        }
    }
}


- (void)didFireDeleteButtonActionForBehaviorCell:(BehaviorCell *)cell {
    if (cell.textField.isEditing) {
        [cell.textField endEditing:YES];
    }

    if ([BLMUtils isObject:cell.behavior.UUID equalToObject:self.addedBehaviorUUID]) {
        [[BLMDataManager sharedManager] deleteBehaviorForUUID:self.addedBehaviorUUID completion:nil];
    } else {
        BLMSessionConfiguration *sessionConfiguration = self.projectSessionConfiguration;
        NSOrderedSet *updatedBehaviorUUIDs = [sessionConfiguration.behaviorUUIDs orderedSetByRemovingObject:cell.behavior.UUID];

        [[BLMDataManager sharedManager] updateSessionConfigurationForUUID:sessionConfiguration.UUID property:BLMSessionConfigurationPropertyBehaviorUUIDs value:updatedBehaviorUUIDs completion:nil];
    }
}


- (void)didChangeToggleSwitchStateForBehaviorCell:(BehaviorCell *)cell {
    [[BLMDataManager sharedManager] updateBehaviorForUUID:cell.behavior.UUID property:BLMBehaviorPropertyContinuous value:@(cell.toggleSwitch.isOn) completion:nil];
}

#pragma mark BLMButtonCellDataSource

- (BOOL)isButtonEnabledForButtonCell:(BLMButtonCell *)cell {
    switch ((Section)cell.section) {
        case SectionBehaviors:
            return ((self.addedBehaviorUUID == nil)
                    || [self isBehaviorName:[[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID].name validForUUID:self.addedBehaviorUUID]);

        case SectionSessions:
        case SectionActionButtons:
            return YES;

        case SectionBasicProperties:
        case SectionSessionProperties:
        case SectionCount: {
            assert(NO);
            return NO;
        }
    }
}


- (nullable UIImage *)imageForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state {
    switch ((Section)cell.section) {
        case SectionBehaviors: {
            assert(cell.item == self.indexPathForAddBehaviorButtonCell.item);

            static UIImage *highlightedPlusSignImage = nil;
            static UIImage *normalPlusSignImage = nil;
            static dispatch_once_t onceToken = 0;

            dispatch_once(&onceToken, ^{
                highlightedPlusSignImage = [BLMViewUtils plusSignImageWithColor:[BLMViewUtils colorForHexCode:BLMColorHexCodePurple]];
                normalPlusSignImage = [BLMViewUtils plusSignImageWithColor:[BLMViewUtils colorForHexCode:BLMColorHexCodeGreen]];
            });

            return ((state == UIControlStateNormal) ? normalPlusSignImage : highlightedPlusSignImage);
        }

        case SectionSessions:
        case SectionActionButtons:
            return nil;

        case SectionBasicProperties:
        case SectionSessionProperties:
        case SectionCount: {
            assert(NO);
            return nil;
        }
    }
}


- (NSAttributedString *)attributedTitleForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state {
    switch ((Section)cell.section) {
        case SectionBehaviors: {
            assert(cell.item == self.indexPathForAddBehaviorButtonCell.item);

            UIColor *titleColor = [BLMViewUtils colorForHexCode:((state == UIControlStateNormal) ? BLMColorHexCodeGreen : BLMColorHexCodePurple)];
            NSDictionary *attributes = @{ NSForegroundColorAttributeName:titleColor, NSFontAttributeName:[UIFont boldSystemFontOfSize:20.0] };

            return [[NSAttributedString alloc] initWithString:@"Add Behavior" attributes:attributes];
        }

        case SectionSessions: {
            NSString *title;
            UIFont *titleFont;
            BLMColorHexCode titleColorHexCode;
            NSOrderedSet *sessionUUIDs = self.project.sessionUUIDs;

            if (cell.item < sessionUUIDs.count) {
                NSUUID *UUID = sessionUUIDs[cell.item];
                BLMSession *session = [[BLMDataManager sharedManager] sessionForUUID:UUID];

                assert(session != nil);

                title = session.name;
                titleFont = [UIFont systemFontOfSize:16.0];
                titleColorHexCode = BLMColorHexCodeBlack;
            } else {
                assert(cell.item == self.indexPathForCreateSessionButtonCell.item);
                title = @"Create Session From Current Configuration";
                titleFont = [UIFont boldSystemFontOfSize:18.0];
                titleColorHexCode = BLMColorHexCodeBlue;
            }

            UIColor *titleColor = [BLMViewUtils colorForHexCode:((state == UIControlStateNormal) ? titleColorHexCode : BLMColorHexCodePurple)];
            NSDictionary *attributes = @{ NSForegroundColorAttributeName:titleColor, NSFontAttributeName:titleFont };

            return [[NSAttributedString alloc] initWithString:title attributes:attributes];
        }

        case SectionActionButtons: {
            NSString *title;
            BLMColorHexCode colorHex;

            switch ((ActionButton)cell.item) {
                case ActionButtonDeleteProject:
                    title = @"Delete Project";
                    colorHex = BLMColorHexCodeRed;
                    break;

                case ActionButtonCount: {
                    assert(NO);
                    return nil;
                }
            }

            UIColor *titleColor = [BLMViewUtils colorForHexCode:((state == UIControlStateNormal) ? colorHex : BLMColorHexCodePurple)];
            NSDictionary *attributes = @{ NSForegroundColorAttributeName:titleColor, NSFontAttributeName:[UIFont systemFontOfSize:18.0] };

            return [[NSAttributedString alloc] initWithString:title attributes:attributes];
        }

        case SectionBasicProperties:
        case SectionSessionProperties:
        case SectionCount: {
            assert(NO);
            return nil;
        }
    }
}

#pragma mark BLMButtonCellDelegate

- (void)didFireActionForButtonCell:(BLMButtonCell *)cell {
    switch ((Section)cell.section) {
        case SectionBehaviors: {
            assert(cell.item == ([self.collectionView numberOfItemsInSection:SectionBehaviors] - 1));

            if (self.addedBehaviorUUID != nil) { // There is a valid behavior item that has not been officially added to the data model
                NSOrderedSet<NSUUID *> *behaviorUUIDs = self.projectSessionConfiguration.behaviorUUIDs;
                NSIndexPath *addedBehaviorIndexPath = [NSIndexPath indexPathForItem:behaviorUUIDs.count inSection:SectionBehaviors];
                BehaviorCell *addedBehaviorCell = (BehaviorCell *)[self.collectionView cellForItemAtIndexPath:addedBehaviorIndexPath];

                assert([BLMUtils isString:addedBehaviorCell.textField.text equalToString:addedBehaviorCell.behavior.name]);
                assert([self isBehaviorName:addedBehaviorCell.textField.text validForUUID:self.addedBehaviorUUID]);
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

                NSOrderedSet<NSUUID *> *behaviorUUIDs = self.projectSessionConfiguration.behaviorUUIDs;
                NSIndexPath *addedBehaviorIndexPath = [NSIndexPath indexPathForItem:behaviorUUIDs.count inSection:SectionBehaviors];

                [self.collectionView performBatchUpdates:^{
                    [self.collectionView insertItemsAtIndexPaths:@[addedBehaviorIndexPath]];
                } completion:^(BOOL finished) {
                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:(behaviorUUIDs.count + 1) inSection:SectionBehaviors]]];
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

        case SectionSessions: {
            NSOrderedSet *sessionUUIDs = self.project.sessionUUIDs;

            if (cell.item < sessionUUIDs.count) {
                NSUUID *UUID = sessionUUIDs[cell.item];
                BLMSession *session = [[BLMDataManager sharedManager] sessionForUUID:UUID];

                assert(session != nil);

                // TODO: Show session details
            } else {
                assert(cell.item == self.indexPathForCreateSessionButtonCell.item);
                // TODO: Create session workflow
//                NSString *name = [NSString stringWithFormat:@"%@-%@-%@", self.project.client, self.project.name, (self.projectSessionConfiguration.observer ?: @"<no_observer>")];
            }
            break;
        }

        case SectionActionButtons: {
            switch ((ActionButton)cell.item) {
                case ActionButtonDeleteProject: {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Delete %@?", self.project.name] message:nil preferredStyle:UIAlertControllerStyleAlert];

                    [alertController addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *__nonnull action) {
                        [[BLMDataManager sharedManager] deleteProjectForUUID:self.projectUUID completion:nil];
                    }]];

                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    alertController.preferredAction = cancelAction;

                    [self presentViewController:alertController animated:YES completion:nil];

                    break;
                }

                case ActionButtonCount: {
                    assert(NO);
                    break;
                }
            }
            break;
        }

        case SectionBasicProperties:
        case SectionSessionProperties:
        case SectionCount: {
            assert(NO);
            break;
        }
    }
}

@end
