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
#import "BLMCollectionView.h"
#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMProjectDetailCollectionViewLayout.h"
#import "BLMProjectDetailController.h"
#import "BLMProjectMenuController.h"
#import "BLMSession.h"
#import "BLMTextInputCell.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"

#import "NSArray+CopyMinusObject.h"
#import "UIResponder+FirstResponder.h"


#pragma mark Constants

static CGFloat const SectionHeaderHeight = 30.0;
static UIEdgeInsets const SectionHeaderInsets = { .top = 0.0, .left = 10.0, .bottom = 10.0, .right = 20.0 };

static UIEdgeInsets const ItemAreaStandardInsets = { .top = 10.0, .left = 20.0, .bottom = 10.0, .right = 20.0 };

static CGFloat const SectionSeparatorHeight = 1.0;
static UIEdgeInsets const SectionSeparatorInsets = { .top = 0.0, .left = 20.0, .bottom = 0.0, .right = 20.0 };

static CGFloat const BehaviorCellDeleteButtonImageRadius = 12.0;
static CGFloat const BehaviorCellDeleteButtonOffset = ((2 * BehaviorCellDeleteButtonImageRadius) / 3.0);


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

@interface BehaviorCellBackgroundView : UIView

@property (nonatomic, strong) UIColor *borderColor;

@end


@implementation BehaviorCellBackgroundView

- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.backgroundColor = [UIColor clearColor];

    _borderColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeBlue alpha:1.0];

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
    self.contentView.backgroundColor = [UIColor clearColor];

    // Delete Button

    static UIImage *deleteButtonDefaultImage = nil;
    static UIImage *deleteButtonSelectedImage = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        deleteButtonDefaultImage = [BLMViewUtils deleteItemImageWithBackgroundColor:[BLMViewUtils colorWithHexValue:0x000000 alpha:0.6] diameter:(BehaviorCellDeleteButtonImageRadius * 2.0)];
        deleteButtonSelectedImage = [BLMViewUtils deleteItemImageWithBackgroundColor:[BLMViewUtils colorWithHexValue:0xB83020 alpha:0.8] diameter:(BehaviorCellDeleteButtonImageRadius * 2.0)];
    });

    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];

    [self.deleteButton setImage:deleteButtonDefaultImage forState:UIControlStateNormal];
    [self.deleteButton setImage:deleteButtonSelectedImage forState:UIControlStateSelected];
    [self.deleteButton setImage:deleteButtonSelectedImage forState:UIControlStateHighlighted];

    [self.deleteButton addTarget:self action:@selector(handleActionForDeleteButton:forEvent:) forControlEvents:UIControlEventTouchUpInside];

    self.deleteButton.backgroundColor = [UIColor clearColor];
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
    backgroundView.borderColor = ([self.delegate shouldAcceptInputForTextInputCell:self] ? [BLMViewUtils colorWithHexValue:BLMColorHexCodeBlue alpha:1.0] : [BLMCollectionViewCell errorColor]);
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
    BLMBehavior *updatedBehavior = notification.userInfo[BLMBehaviorNewBehaviorUserInfoKey];
    assert([BLMUtils isObject:updatedBehavior equalToObject:[[BLMDataManager sharedManager] behaviorForUUID:self.behavior.UUID]]);

    self.behavior = updatedBehavior;

    [self updateContent];
}


- (void)configureLabelSubviewsPreferredMaxLayoutWidth {
    [super configureLabelSubviewsPreferredMaxLayoutWidth];

    self.toggleSwitchLabel.preferredMaxLayoutWidth = CGRectGetWidth([self.toggleSwitchLabel alignmentRectForFrame:self.toggleSwitchLabel.frame]);
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

@interface BLMProjectDetailController () <UICollectionViewDataSource, BLMCollectionViewLayoutDelegate, BehaviorCellDelegate, BLMButtonCellDelegate>

@property (nonatomic, strong, readonly) BLMCollectionView *collectionView;
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
    self.edgesForExtendedLayout = UIRectEdgeNone;

    _collectionView = [[BLMCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[[BLMProjectDetailCollectionViewLayout alloc] init]];

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
    self.collectionView.backgroundColor = [BLMViewUtils colorWithHexValue:BLMColorHexCodeDefaultBackground alpha:1.0];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.collectionView];
    [self.view addConstraints:[BLMViewUtils constraintsForItem:self.collectionView equalToItem:self.view]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:self.project];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionConfigurationUpdated:) name:BLMSessionConfigurationUpdatedNotification object:self.projectSessionConfiguration];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBehaviorUpdated:) name:BLMBehaviorUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBehaviorDeleted:) name:BLMBehaviorDeletedNotification object:nil];
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

    for (BLMBehavior *behavior in self.projectSessionConfiguration.behaviorEnumerator) {
        if (![BLMUtils isObject:behavior.UUID equalToObject:UUID] && [BLMUtils isString:lowercaseName equalToString:behavior.name.lowercaseString]) {
            return NO;
        }
    }

    return YES;
}


- (void)updateProjectSessionConfigurationWithAddedBehaviorUUID {
    BLMSessionConfiguration *sessionConfiguration = self.projectSessionConfiguration;
    NSArray *updatedBehaviorUUIDs = [sessionConfiguration.behaviorUUIDs arrayByAddingObject:self.addedBehaviorUUID];

    assert(self.addedBehaviorUUID != nil);
    assert(![sessionConfiguration.behaviorUUIDs containsObject:self.addedBehaviorUUID]);
    assert([self isBehaviorName:[[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID].name validForUUID:self.addedBehaviorUUID]);

    [[BLMDataManager sharedManager] updateSessionConfigurationForUUID:sessionConfiguration.UUID property:BLMSessionConfigurationPropertyBehaviorUUIDs value:updatedBehaviorUUIDs completion:nil];

    assert(self.addedBehaviorUUID == nil);
}


- (NSIndexPath *)indexPathForAddBehaviorButtonCell {
    NSUInteger cellItem = ([self.collectionView numberOfItemsInSection:BLMProjectDetailSectionBehaviors] - 1);
    return [NSIndexPath indexPathForItem:cellItem inSection:BLMProjectDetailSectionBehaviors];
}


- (void)updateBottomInset:(CGFloat)bottomInset afterDelay:(NSTimeInterval)delay duration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve completion:(void(^)(BOOL finished))completion {
    if (self.collectionView.contentInset.bottom == bottomInset) {
        return;
    }

    UIViewAnimationOptions options = (curve << 16); // The UIViewAnimationOptions constants regarding animation curve are UIViewAnimationCurve enum values bit-shifted left by 16

    UIEdgeInsets contentInset = self.collectionView.contentInset;
    contentInset.bottom = bottomInset;

    [UIView animateWithDuration:duration delay:delay options:options animations:^{
        self.collectionView.contentInset = contentInset;
    } completion:completion];
}

#pragma mark Event Handling

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    CGRect keyboardScreenFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardWindowFrame = [self.view.window convertRect:keyboardScreenFrame fromWindow:nil];
    CGRect keyboardViewFrame = [self.view convertRect:keyboardWindowFrame fromView:nil];

    CGFloat bottomInset = (CGRectGetMaxY(self.collectionView.frame) - CGRectGetMinY(keyboardViewFrame));//MAX(self.collectionView.contentInset.bottom, CGRectGetMinY(keyboardViewFrame));
    NSTimeInterval duration = [BLMUtils doubleFromDictionary:notification.userInfo forKey:UIKeyboardAnimationDurationUserInfoKey defaultValue:0.0];
    UIViewAnimationCurve curve = [BLMUtils integerFromDictionary:notification.userInfo forKey:UIKeyboardAnimationCurveUserInfoKey defaultValue:UIViewAnimationCurveLinear];

    [self updateBottomInset:bottomInset afterDelay:0.0 duration:duration curve:curve completion:^(BOOL finished) {
        UIResponder *firstResponder = [UIResponder currentFirstResponder];
        assert(firstResponder != nil);

        if (![firstResponder isKindOfClass:[BLMCollectionViewCellTextField class]]) {
            return;
        }

        BLMCollectionViewCellTextField *textField = (BLMCollectionViewCellTextField *)firstResponder;
        id<BLMCollectionViewCellTextFieldDelegate> delegate = textField.delegate;
        NSIndexPath *indexPath = [delegate indexPathForCollectionViewCellTextField:textField];
        UICollectionViewLayoutAttributes *cellLayout = [(BLMProjectDetailCollectionViewLayout *)self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];

        [self.collectionView scrollRectToVisible:cellLayout.frame animated:YES];
    }];
}


- (void)handleKeyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [BLMUtils doubleFromDictionary:notification.userInfo forKey:UIKeyboardAnimationDurationUserInfoKey defaultValue:0.0];
    UIViewAnimationCurve curve = [BLMUtils integerFromDictionary:notification.userInfo forKey:UIKeyboardAnimationCurveUserInfoKey defaultValue:UIViewAnimationCurveLinear];

    [self updateBottomInset:0.0 afterDelay:0.0 duration:duration curve:curve completion:nil];
}


- (void)handleProjectUpdated:(NSNotification *)notification {
    BLMProject *original = (BLMProject *)notification.userInfo[BLMProjectOldProjectUserInfoKey];
    assert(original == notification.object);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMProjectUpdatedNotification object:original];

    BLMProject *updated = (BLMProject *)notification.userInfo[BLMProjectNewProjectUserInfoKey];
    assert(updated == self.project);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:updated];

    if (![BLMUtils isObject:original.sessionConfigurationUUID equalToObject:updated.sessionConfigurationUUID]) {
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:BLMProjectDetailSectionBehaviors]];
    }
}


- (void)handleSessionConfigurationUpdated:(NSNotification *)notification {
    BLMSessionConfiguration *original = (BLMSessionConfiguration *)notification.userInfo[BLMSessionConfigurationOldSessionConfigurationUserInfoKey];
    assert(original == notification.object);

    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMSessionConfigurationUpdatedNotification object:original];

    BLMSessionConfiguration *updated = (BLMSessionConfiguration *)notification.userInfo[BLMSessionConfigurationNewSessionConfigurationUserInfoKey];
    assert(updated == self.projectSessionConfiguration);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSessionConfigurationUpdated:) name:BLMSessionConfigurationUpdatedNotification object:updated];

    if ([BLMUtils isArray:original.behaviorUUIDs equalToArray:updated.behaviorUUIDs]) {
        return;
    }

    [self.collectionView performBatchUpdates:^{
        NSMutableArray *deletedIndexPaths = [NSMutableArray array];

        NSMutableSet *deletedUUIDs = [NSMutableSet setWithArray:original.behaviorUUIDs];
        [deletedUUIDs minusSet:[NSSet setWithArray:updated.behaviorUUIDs]];

        for (NSUUID *UUID in deletedUUIDs) {
            [deletedIndexPaths addObject:[NSIndexPath indexPathForItem:[original.behaviorUUIDs indexOfObject:UUID] inSection:BLMProjectDetailSectionBehaviors]];
        }

        NSMutableSet<NSUUID *> *insertedUUIDs = [NSMutableSet setWithArray:updated.behaviorUUIDs];
        [insertedUUIDs minusSet:[NSMutableSet setWithArray:original.behaviorUUIDs]];

        NSMutableArray *insertedIndexPaths = [NSMutableArray array];
        NSMutableArray *reloadIndexPaths = [NSMutableArray arrayWithObject:[self indexPathForAddBehaviorButtonCell]];

        if ([insertedUUIDs containsObject:self.addedBehaviorUUID]) {
            [insertedUUIDs removeObject:self.addedBehaviorUUID];
            [reloadIndexPaths addObject:[NSIndexPath indexPathForItem:[updated.behaviorUUIDs indexOfObject:self.addedBehaviorUUID] inSection:BLMProjectDetailSectionBehaviors]];

            self.addedBehaviorUUID = nil;
        }

        for (NSUUID *UUID in insertedUUIDs) {
            [insertedIndexPaths addObject:[NSIndexPath indexPathForItem:[updated.behaviorUUIDs indexOfObject:UUID] inSection:BLMProjectDetailSectionBehaviors]];
        }

        [self.collectionView deleteItemsAtIndexPaths:deletedIndexPaths];
        [self.collectionView insertItemsAtIndexPaths:insertedIndexPaths];
        [self.collectionView reloadItemsAtIndexPaths:reloadIndexPaths];
    } completion:^(BOOL finished) {
        assert(finished);
    }];
}


- (void)handleBehaviorUpdated:(NSNotification *)notification {
    BLMBehavior *behavior = (BLMBehavior *)notification.object;
    BOOL updatedBehaviorIsAddedBehavior = [BLMUtils isObject:behavior.UUID equalToObject:self.addedBehaviorUUID];
    NSArray<NSUUID *> *behaviorUUIDs = self.projectSessionConfiguration.behaviorUUIDs;

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
    NSArray<NSUUID *> *behaviorUUIDs = sessionConfiguration.behaviorUUIDs;

    if ([BLMUtils isObject:behavior.UUID equalToObject:self.addedBehaviorUUID]) {
        assert(![behaviorUUIDs containsObject:self.addedBehaviorUUID]);

        [self.collectionView performBatchUpdates:^{
            self.addedBehaviorUUID = nil;
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:behaviorUUIDs.count inSection:BLMProjectDetailSectionBehaviors]]];
            [self.collectionView reloadItemsAtIndexPaths:@[[self indexPathForAddBehaviorButtonCell]]];
        } completion:^(BOOL finished) {
            assert(finished);
        }];
    } else if ([behaviorUUIDs containsObject:behavior.UUID]) {
        NSArray *updatedBehaviorUUIDs = [behaviorUUIDs arrayByRemovingObject:behavior.UUID];

        [[BLMDataManager sharedManager] updateSessionConfigurationForUUID:sessionConfiguration.UUID property:BLMSessionConfigurationPropertyBehaviorUUIDs value:updatedBehaviorUUIDs completion:nil];
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return BLMProjectDetailSectionCount;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = 0;

    switch ((BLMProjectDetailSection)section) {
        case BLMProjectDetailSectionBasicInfo: {
            numberOfItems = BasicInfoSectionItemCount;
            break;
        }

        case BLMProjectDetailSectionSessionProperties: {
            numberOfItems = SessionPropertiesSectionItemCount;
            break;
        }

        case BLMProjectDetailSectionBehaviors: {
            numberOfItems = self.projectSessionConfiguration.behaviorUUIDs.count;

            if (self.addedBehaviorUUID != nil) {
                numberOfItems += 1; // +1 for the BLMBehavior that's been added to the data model but not to a session configuration
            }

            numberOfItems += 1; // +1 for the add behavior button cell
            break;
        }

        case BLMProjectDetailSectionActionButtons: {
            numberOfItems = ActionButtonsSectionItemCount;
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
    BLMCollectionViewCell *cell = nil;

    switch ((BLMProjectDetailSection)indexPath.section) {
        case BLMProjectDetailSectionBasicInfo:
        case BLMProjectDetailSectionSessionProperties: {
            BLMTextInputCell *textInputCell = (BLMTextInputCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMTextInputCell class]) forIndexPath:indexPath];
            textInputCell.delegate = self;

            cell = textInputCell;
            break;
        }

        case BLMProjectDetailSectionBehaviors: {
            NSArray<NSUUID *> *behaviorUUIDs = self.projectSessionConfiguration.behaviorUUIDs;

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

        case BLMProjectDetailSectionActionButtons: {
            BLMButtonCell *buttonCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMButtonCell class]) forIndexPath:indexPath];
            buttonCell.delegate = self;

            cell = buttonCell;
            break;
        }

        case BLMProjectDetailSectionCount: {
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

        switch ((BLMProjectDetailSection)indexPath.section) {
            case BLMProjectDetailSectionBasicInfo: {
                assert(NO);
                break;
            }

            case BLMProjectDetailSectionSessionProperties: {
                headerView.label.text = @"Default Session Properties";
                break;
            }

            case BLMProjectDetailSectionBehaviors: {
                headerView.label.text = @"Behaviors";
                break;
            }

            case BLMProjectDetailSectionActionButtons: {
                assert(NO);
                break;
            }
                
            case BLMProjectDetailSectionCount: {
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
    switch ((BLMProjectDetailSection)section) {
        case BLMProjectDetailSectionBasicInfo: {
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

        case BLMProjectDetailSectionSessionProperties: {
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

        case BLMProjectDetailSectionBehaviors: {
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
                    .Height = SectionSeparatorHeight,
                    .Insets = SectionSeparatorInsets
                }
            };
        }

        case BLMProjectDetailSectionActionButtons: {
            return (BLMCollectionViewSectionLayout) {
                .Header = {
                    .Height = 0.0,
                    .Insets = UIEdgeInsetsZero
                },
                .ItemArea = {
                    .HasBackground = NO,
                    .Insets = ItemAreaStandardInsets,
                    .Grid = {
                        .ColumnCount = 3,
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

        case BLMProjectDetailSectionCount: {
            assert(NO);
            return BLMCollectionViewSectionLayoutNull;
        }
    }
}

#pragma mark BLMToggleSwitchTextInputCellDelegate

- (NSString *)labelForTextInputCell:(BLMTextInputCell *)cell {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBasicInfo: {
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

        case BLMProjectDetailSectionSessionProperties: {
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

        case BLMProjectDetailSectionBehaviors:
            return @"Name:";

        case BLMProjectDetailSectionActionButtons:
        case BLMProjectDetailSectionCount: {
            break;
        }
    }

    assert(NO);
    return nil;
}


- (NSString *)defaultInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBasicInfo: {
            switch ((BasicInfoSectionItem)cell.item) {
                case BasicInfoSectionItemProjectName:
                    return self.project.name;

                case BasicInfoSectionItemClientName:
                    return self.project.client;

                case BasicInfoSectionItemCount: {
                    assert(NO);
                    break;
                }
            }
        }

        case BLMProjectDetailSectionSessionProperties: {
            switch ((SessionPropertiesSectionItem)cell.item) {
                case SessionPropertiesSectionItemCondition:
                    return self.projectSessionConfiguration.condition;

                case SessionPropertiesSectionItemLocation:
                    return self.projectSessionConfiguration.location;

                case SessionPropertiesSectionItemTherapist:
                    return self.projectSessionConfiguration.therapist;

                case SessionPropertiesSectionItemObserver:
                    return self.projectSessionConfiguration.observer;

                case SessionPropertiesSectionItemCount: {
                    assert(NO);
                    break;
                }
            }
        }

        case BLMProjectDetailSectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            NSUUID *UUID = behaviorCell.behavior.UUID;

            return [[BLMDataManager sharedManager] behaviorForUUID:UUID].name;
        }

        case BLMProjectDetailSectionActionButtons:
        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    assert(NO);
    return nil;
}


- (NSAttributedString *)attributedPlaceholderForTextInputCell:(BLMTextInputCell *)cell {
    NSString *placeholder = nil;
    NSDictionary *attributes = nil;
    
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBasicInfo:
            placeholder = [NSString stringWithFormat:@"Required (%lu+ characters)", (unsigned long)[self minimumInputLengthForTextInputCell:cell]];
            attributes = [BLMTextInputCell errorAttributes];
            break;

        case BLMProjectDetailSectionSessionProperties:
            placeholder = @"Optional";
            break;

        case BLMProjectDetailSectionBehaviors:
            placeholder = [NSString stringWithFormat:@"%lu+ characters", (unsigned long)[self minimumInputLengthForTextInputCell:cell]];
            attributes = [BLMTextInputCell errorAttributes];
            break;

        case BLMProjectDetailSectionActionButtons:
        case BLMProjectDetailSectionCount: {
            assert(NO);
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
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBasicInfo: {
            switch ((BasicInfoSectionItem)cell.item) {
                case BasicInfoSectionItemProjectName:
                    return BLMProjectNameMinimumLength;

                case BasicInfoSectionItemClientName:
                    return BLMProjectClientMinimumLength;

                case BasicInfoSectionItemCount: {
                    assert(NO);
                    break;
                }
            }
        }

        case BLMProjectDetailSectionSessionProperties: {
            switch ((SessionPropertiesSectionItem)cell.item) {
                case SessionPropertiesSectionItemCondition:
                case SessionPropertiesSectionItemLocation:
                case SessionPropertiesSectionItemTherapist:
                case SessionPropertiesSectionItemObserver:
                    return 0;

                case SessionPropertiesSectionItemCount: {
                    assert(NO);
                    break;
                }
            }
        }

        case BLMProjectDetailSectionBehaviors:
            return BLMBehaviorNameMinimumLength;

        case BLMProjectDetailSectionActionButtons:
        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    assert(NO);
    return 0;
}


- (void)didChangeInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            NSUUID *UUID = behaviorCell.behavior.UUID;

            if ([BLMUtils isObject:UUID equalToObject:self.addedBehaviorUUID]) { // Update the added behavior on every cell text change, but ignore established behaviors' cells until they call didAcceptInputForTextInputCell:
                [[BLMDataManager sharedManager] updateBehaviorForUUID:UUID property:BLMBehaviorPropertyName value:cell.textField.text completion:nil];
            }

            [behaviorCell updateBorderColor];
            break;
        }

        case BLMProjectDetailSectionBasicInfo:
        case BLMProjectDetailSectionSessionProperties:
        case BLMProjectDetailSectionActionButtons:
            break;

        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
}


- (BOOL)shouldAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBasicInfo:
            return (cell.textField.text.length >= [self minimumInputLengthForTextInputCell:cell]);

        case BLMProjectDetailSectionSessionProperties:
            return YES;

        case BLMProjectDetailSectionBehaviors: {
            BehaviorCell *behaviorCell = (BehaviorCell *)cell;
            return [self isBehaviorName:cell.textField.text validForUUID:behaviorCell.behavior.UUID];
        }

        case BLMProjectDetailSectionActionButtons:
        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
}


- (void)didAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBasicInfo: {
            BLMProjectProperty updatedProperty;

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

            [[BLMDataManager sharedManager] updateProjectForUUID:self.projectUUID property:updatedProperty value:cell.textField.text completion:nil];
            break;
        }

        case BLMProjectDetailSectionSessionProperties: {
            BLMSessionConfigurationProperty updatedProperty;

            switch ((SessionPropertiesSectionItem)cell.item) {
                case SessionPropertiesSectionItemCondition:
                    updatedProperty = BLMSessionConfigurationPropertyCondition;
                    break;

                case SessionPropertiesSectionItemLocation:
                    updatedProperty = BLMSessionConfigurationPropertyLocation;
                    break;

                case SessionPropertiesSectionItemTherapist:
                    updatedProperty = BLMSessionConfigurationPropertyTherapist;
                    break;

                case SessionPropertiesSectionItemObserver:
                    updatedProperty = BLMSessionConfigurationPropertyObserver;
                    break;

                case SessionPropertiesSectionItemCount: {
                    assert(NO);
                    break;
                }
            }

            [[BLMDataManager sharedManager] updateSessionConfigurationForUUID:self.project.sessionConfigurationUUID property:updatedProperty value:cell.textField.text completion:nil];
            break;
        }

        case BLMProjectDetailSectionBehaviors: {
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

        case BLMProjectDetailSectionActionButtons:
        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
}

#pragma mark BehaviorCellDelegate

- (void)didFireDeleteButtonActionForBehaviorCell:(BehaviorCell *)cell {
    if ([BLMUtils isObject:cell.behavior.UUID equalToObject:self.addedBehaviorUUID]) {
        [[BLMDataManager sharedManager] deleteBehaviorForUUID:self.addedBehaviorUUID completion:nil];
    } else {
        BLMSessionConfiguration *sessionConfiguration = self.projectSessionConfiguration;
        NSArray *updatedBehaviorUUIDs = [sessionConfiguration.behaviorUUIDs arrayByRemovingObject:cell.behavior.UUID];

        [[BLMDataManager sharedManager] updateSessionConfigurationForUUID:sessionConfiguration.UUID property:BLMSessionConfigurationPropertyBehaviorUUIDs value:updatedBehaviorUUIDs completion:nil];
    }
}


- (void)didChangeToggleSwitchStateForBehaviorCell:(BehaviorCell *)cell {
    [[BLMDataManager sharedManager] updateBehaviorForUUID:cell.behavior.UUID property:BLMBehaviorPropertyContinuous value:@(cell.toggleSwitch.isOn) completion:nil];
}

#pragma mark BLMButtonCellDelegate

- (BOOL)isButtonEnabledForButtonCell:(BLMButtonCell *)cell {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBehaviors:
            return ((self.addedBehaviorUUID == nil)
                    || [self isBehaviorName:[[BLMDataManager sharedManager] behaviorForUUID:self.addedBehaviorUUID].name validForUUID:self.addedBehaviorUUID]);

        case BLMProjectDetailSectionActionButtons:
            return YES;

        case BLMProjectDetailSectionBasicInfo:
        case BLMProjectDetailSectionSessionProperties:
        case BLMProjectDetailSectionCount: {
            assert(NO);
            return NO;
        }
    }
}


- (UIImage *)imageForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBehaviors: {
            assert(cell.item == self.indexPathForAddBehaviorButtonCell.item);

            static UIImage *highlightedPlusSignImage = nil;
            static UIImage *normalPlusSignImage = nil;
            static dispatch_once_t onceToken = 0;

            dispatch_once(&onceToken, ^{
                highlightedPlusSignImage = [BLMViewUtils plusSignImageWithColor:[BLMViewUtils colorWithHexValue:BLMColorHexCodePurple alpha:1.0]];
                normalPlusSignImage = [BLMViewUtils plusSignImageWithColor:[BLMViewUtils colorWithHexValue:BLMColorHexCodeGreen alpha:1.0]];
            });

            return ((state == UIControlStateNormal) ? normalPlusSignImage : highlightedPlusSignImage);
        }

        case BLMProjectDetailSectionActionButtons:
            break;

        case BLMProjectDetailSectionBasicInfo:
        case BLMProjectDetailSectionSessionProperties:
        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return nil;
}


- (NSAttributedString *)attributedTitleForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBehaviors: {
            assert(cell.item == self.indexPathForAddBehaviorButtonCell.item);

            BLMColorHexCode colorHexValue = ((state == UIControlStateNormal) ? BLMColorHexCodeGreen : BLMColorHexCodePurple);
            NSDictionary *attributes = @{ NSForegroundColorAttributeName:[BLMViewUtils colorWithHexValue:colorHexValue alpha:1.0], NSFontAttributeName:[UIFont boldSystemFontOfSize:20.0] };

            return [[NSAttributedString alloc] initWithString:@"Add Behavior" attributes:attributes];
        }

        case BLMProjectDetailSectionActionButtons: {
            BLMColorHexCode colorHexValue = ((state == UIControlStateNormal) ? BLMColorHexCodeBlue : BLMColorHexCodePurple);
            NSDictionary *attributes = @{ NSForegroundColorAttributeName:[BLMViewUtils colorWithHexValue:colorHexValue alpha:1.0] };

            switch ((ActionButtonsSectionItem)cell.item) {
                case ActionButtonsSectionItemCreateSession:
                    return [[NSAttributedString alloc] initWithString:@"Create Session" attributes:attributes];

                case ActionButtonsSectionItemViewSessionHistory:
                    return [[NSAttributedString alloc] initWithString:@"View Session History" attributes:attributes];

                case ActionButtonsSectionItemDeleteProject:
                    return [[NSAttributedString alloc] initWithString:@"Delete Project" attributes:attributes];

                case ActionButtonsSectionItemCount: {
                    assert(NO);
                    return nil;
                }
            }
        }

        case BLMProjectDetailSectionBasicInfo:
        case BLMProjectDetailSectionSessionProperties:
        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }

    return nil;
}


- (void)didFireActionForButtonCell:(BLMButtonCell *)cell {
    switch ((BLMProjectDetailSection)cell.section) {
        case BLMProjectDetailSectionBehaviors: {
            assert(cell.item == ([self.collectionView numberOfItemsInSection:BLMProjectDetailSectionBehaviors] - 1));

            if (self.addedBehaviorUUID != nil) { // There is a valid behavior item that has not been officially added to the data model
                NSArray<NSUUID *> *behaviorUUIDs = self.projectSessionConfiguration.behaviorUUIDs;
                NSIndexPath *addedBehaviorIndexPath = [NSIndexPath indexPathForItem:behaviorUUIDs.count inSection:BLMProjectDetailSectionBehaviors];
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

                NSArray<NSUUID *> *behaviorUUIDs = self.projectSessionConfiguration.behaviorUUIDs;
                NSIndexPath *addedBehaviorIndexPath = [NSIndexPath indexPathForItem:behaviorUUIDs.count inSection:BLMProjectDetailSectionBehaviors];

                [self.collectionView performBatchUpdates:^{
                    [self.collectionView insertItemsAtIndexPaths:@[addedBehaviorIndexPath]];
                } completion:^(BOOL finished) {
                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:(behaviorUUIDs.count + 1) inSection:BLMProjectDetailSectionBehaviors]]];
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

        case BLMProjectDetailSectionActionButtons: {
            switch ((ActionButtonsSectionItem)cell.item) {
                case ActionButtonsSectionItemCreateSession:
                    break;

                case ActionButtonsSectionItemViewSessionHistory:
                    break;

                case ActionButtonsSectionItemDeleteProject:
                    break;

                case ActionButtonsSectionItemCount: {
                    assert(NO);
                    break;
                }
            }
            break;
        }

        case BLMProjectDetailSectionBasicInfo:
        case BLMProjectDetailSectionSessionProperties:
        case BLMProjectDetailSectionCount: {
            assert(NO);
            break;
        }
    }
}

@end
