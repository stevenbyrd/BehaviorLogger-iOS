//
//  BLMCreateProjectController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/11/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMButtonCell.h"
#import "BLMCollectionView.h"
#import "BLMCreateProjectController.h"
#import "BLMDataManager.h"
#import "BLMTextInputCell.h"
#import "BLMTextField.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"

#import "UIResponder+BLMAdditions.h"


#pragma mark Constants

static CGFloat const SectionHeaderHeight = 30.0;
static UIEdgeInsets const SectionHeaderInsets = { .top = 0.0, .left = 10.0, .bottom = 10.0, .right = 20.0 };

static CGFloat const SectionSeparatorHeight = 1.0;
static UIEdgeInsets const SectionSeparatorInsets = { .top = 10.0, .left = 20.0, .bottom = 0.0, .right = 20.0 };

static UIEdgeInsets const ItemAreaStandardInsets = { .top = 5.0, .left = 20.0, .bottom = 10.0, .right = 20.0 };


typedef NS_ENUM(NSUInteger, Section) {
    SectionProjectProperties,
    SectionSessionConfigurationProperties,
    SectionActionButtons,
    SectionCount
};


typedef NS_ENUM(NSUInteger, ProjectProperty) {
    ProjectPropertyName,
    ProjectPropertyClient,
    ProjectPropertyCount
};


typedef NS_ENUM(NSUInteger, SessionConfigurationProperty) {
    SessionConfigurationPropertyCondition,
    SessionConfigurationPropertyLocation,
    SessionConfigurationPropertyTherapist,
    SessionConfigurationPropertyObserver,
    SessionConfigurationPropertyCount
};


typedef NS_ENUM(NSUInteger, ActionButton) {
    ActionButtonCreateProject,
    ActionButtonCancel,
    ActionButtonCount
};


#pragma mark

@interface BLMCreateProjectController () < UICollectionViewDataSource, BLMCollectionViewLayoutDelegate, BLMCollectionViewCellDataSource, BLMButtonCellDataSource, BLMButtonCellDelegate, BLMTextInputCellDataSource, BLMTextInputCellDelegate>

@property (nonatomic, copy, readonly) NSArray<NSMutableArray<NSString *> *> *properties;
@property (nonatomic, assign, getter=shouldAutomaticallyBeginEditingProjectName) BOOL automaticallyBeginEditingProjectName;
@property (nonatomic, strong, readonly) BLMCollectionView *collectionView;

@end


@implementation BLMCreateProjectController

- (instancetype)initWithDelegate:(id<BLMCreateProjectControllerDelegate>)delegate {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _delegate = delegate;
    _automaticallyBeginEditingProjectName = YES;
    _properties = @[[NSMutableArray array], [NSMutableArray array]];

    for (ProjectProperty property = 0; property < ProjectPropertyCount; property += 1) {
        [self.properties[SectionProjectProperties] addObject:@""];
    }

    for (SessionConfigurationProperty property = 0; property < SessionConfigurationPropertyCount; property += 1) {
        [self.properties[SectionSessionConfigurationProperties] addObject:@""];
    }

    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Create Project";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    _collectionView = [[BLMCollectionView alloc] initWithFrame:CGRectZero];

    [self.collectionView registerClass:[BLMSectionHeaderView class] forSupplementaryViewOfKind:BLMCollectionViewKindHeader withReuseIdentifier:NSStringFromClass([BLMSectionHeaderView class])];
    [self.collectionView registerClass:[BLMSectionSeparatorFooterView class] forSupplementaryViewOfKind:BLMCollectionViewKindFooter withReuseIdentifier:NSStringFromClass([BLMSectionSeparatorFooterView class])];

    [self.collectionView registerClass:[BLMTextInputCell class] forCellWithReuseIdentifier:NSStringFromClass([BLMTextInputCell class])];
    [self.collectionView registerClass:[BLMButtonCell class] forCellWithReuseIdentifier:NSStringFromClass([BLMButtonCell class])];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.scrollEnabled = YES;
    self.collectionView.bounces = YES;
    self.collectionView.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeDefaultBackground];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.collectionView];
    [self.view addConstraints:[BLMViewUtils constraintsForItem:self.collectionView equalToItem:self.view]];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (self.shouldAutomaticallyForwardAppearanceMethods) {
        self.automaticallyBeginEditingProjectName = NO;

        [self.collectionView layoutIfNeeded];

        BLMTextInputCell *projectNameCell = (BLMTextInputCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:ProjectPropertyName inSection:SectionProjectProperties]];

        assert([projectNameCell isKindOfClass:[BLMTextInputCell class]]);
        assert(projectNameCell.textField.text.length == 0);
        assert([UIResponder currentFirstResponder] == nil);

        [projectNameCell.textField becomeFirstResponder];
    }
}

#pragma mark Internal State

- (NSUInteger)minimumInputLengthForSection:(Section)section property:(NSUInteger)property {
    switch (section) {
        case SectionProjectProperties: {
            switch ((ProjectProperty)property) {
                case ProjectPropertyName:
                    return BLMProjectNameMinimumLength;

                case ProjectPropertyClient:
                    return BLMProjectClientMinimumLength;

                case ProjectPropertyCount: {
                    assert(NO);
                    return 0;
                }
            }
        }

        case SectionSessionConfigurationProperties:
            return 0;

        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return 0;
        }
    }
}


- (BOOL)isTextInput:(NSString *)textInput validForSection:(Section)section property:(NSUInteger)property {
    switch (section) {
        case SectionProjectProperties: {
            switch ((ProjectProperty)property) {
                case ProjectPropertyName: {
                    if ([[BLMDataManager sharedManager].projectNameSet containsObject:textInput]) {
                        return NO;
                    }
                }

                case ProjectPropertyClient:
                    return (textInput.length >= [self minimumInputLengthForSection:section property:property]);

                case ProjectPropertyCount: {
                    assert(NO);
                    return NO;
                }
            }
        }
            
        case SectionSessionConfigurationProperties:
            return (textInput.length >= [self minimumInputLengthForSection:section property:property]);

        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return NO;
        }
    }
}


- (BOOL)isAllTextInputValid {
    assert([NSThread isMainThread]);

    for (NSUInteger section = 0; section < self.properties.count; section += 1) {
        for (NSUInteger property = 0; property < self.properties[section].count; property += 1) {
            if (![self isTextInput:self.properties[section][property] validForSection:section property:property]) {
                return NO;
            }
        }
    }

    return YES;
}


- (void)createProjectFromTextInput {
    assert(self.isAllTextInputValid);

    [[BLMDataManager sharedManager] createSessionConfigurationWithCondition:self.properties[SectionSessionConfigurationProperties][SessionConfigurationPropertyCondition]
                                                                   location:self.properties[SectionSessionConfigurationProperties][SessionConfigurationPropertyLocation]
                                                                  therapist:self.properties[SectionSessionConfigurationProperties][SessionConfigurationPropertyTherapist]
                                                                   observer:self.properties[SectionSessionConfigurationProperties][SessionConfigurationPropertyObserver]
                                                                  timeLimit:0
                                                           timeLimitOptions:0
                                                              behaviorUUIDs:nil
                                                                 completion:^(BLMSessionConfiguration *sessionConfiguration, NSError *sessionConfigurationError) {
                                                                     if (sessionConfigurationError != nil) {
                                                                         [self.delegate createProjectController:self didFailWithError:sessionConfigurationError];
                                                                     } else {
                                                                         [[BLMDataManager sharedManager] createProjectWithName:self.properties[SectionProjectProperties][ProjectPropertyName]
                                                                                                                        client:self.properties[SectionProjectProperties][ProjectPropertyClient]
                                                                                                      sessionConfigurationUUID:sessionConfiguration.UUID
                                                                                                                    completion:^(BLMProject *project, NSError *projectError) {
                                                                                                                        if (projectError != nil) {
                                                                                                                            [self.delegate createProjectController:self didFailWithError:projectError];
                                                                                                                        } else {
                                                                                                                            [self.delegate createProjectController:self didCreateProject:project];
                                                                                                                        }
                                                                                                                    }];
                                                                     }
                                                                 }];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return SectionCount;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger itemCount = 0;

    switch ((Section)section) {
        case SectionProjectProperties: {
            itemCount = ProjectPropertyCount;
            break;
        }

        case SectionSessionConfigurationProperties: {
            itemCount = SessionConfigurationPropertyCount;
            break;
        }

        case SectionActionButtons: {
            itemCount = ActionButtonCount;
            break;
        }

        case SectionCount: {
            assert(NO);
            break;
        }
    }

    return itemCount;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BLMCollectionViewCell *cell = nil;

    switch ((Section)indexPath.section) {
        case SectionProjectProperties:
        case SectionSessionConfigurationProperties: {
            BLMTextInputCell *textInputCell = (BLMTextInputCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BLMTextInputCell class]) forIndexPath:indexPath];
            textInputCell.dataSource = self;
            textInputCell.delegate = self;

            cell = textInputCell;
            break;
        }

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

    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = nil;

    if ([BLMUtils isString:kind equalToString:BLMCollectionViewKindHeader]) {
        BLMSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([BLMSectionHeaderView class]) forIndexPath:indexPath];

        view = headerView;

        switch ((Section)indexPath.section) {
            case SectionProjectProperties: {
                headerView.label.text = @"Basic Info";
                break;
            }

            case SectionSessionConfigurationProperties: {
                headerView.label.text = @"Session Properties";
                break;
            }

            case SectionActionButtons:
            case SectionCount: {
                assert(NO);
                break;
            }
        }
    } else if ([BLMUtils isString:kind equalToString:BLMCollectionViewKindFooter]) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([BLMSectionSeparatorFooterView class]) forIndexPath:indexPath];
    }

    return view;
}

#pragma mark UICollectionViewDelegate / BLMCollectionViewLayoutDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    assert([cell isKindOfClass:[BLMCollectionViewCell class]]);
    [(BLMCollectionViewCell *)cell updateContent];
}


- (BLMCollectionViewSectionLayout)collectionView:(BLMCollectionView *)collectionView layoutForSection:(NSUInteger)section {
    switch ((Section)section) {
        case SectionProjectProperties: {
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

        case SectionSessionConfigurationProperties: {
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
                        .ColumnCount = 2,
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

#pragma mark BLMCollectionViewCellDataSource

- (NSString *)labelTextForCollectionViewCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionProjectProperties: {
            switch ((ProjectProperty)cell.item) {
                case ProjectPropertyName:
                    return @"Project:";

                case ProjectPropertyClient:
                    return @"Client:";

                case ProjectPropertyCount: {
                    assert(NO);
                    break;
                }
            }
        }

        case SectionSessionConfigurationProperties: {
            switch ((SessionConfigurationProperty)cell.item) {
                case SessionConfigurationPropertyCondition:
                    return @"Condition:";

                case SessionConfigurationPropertyLocation:
                    return @"Location:";

                case SessionConfigurationPropertyTherapist:
                    return @"Therapist:";

                case SessionConfigurationPropertyObserver:
                    return @"Observer:";

                case SessionConfigurationPropertyCount: {
                    assert(NO);
                    break;
                }
            }
        }

        case SectionActionButtons:
            return nil;

        case SectionCount: {
            assert(NO);
            return nil;
        }
    }
    
    assert(NO);
    return nil;
}

#pragma mark BLMTextInputCellDataSource

- (NSString *)defaultInputForTextInputCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionProjectProperties:
        case SectionSessionConfigurationProperties:
            return self.properties[cell.section][cell.item];

        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return nil;
        }
    }
}


- (NSAttributedString *)attributedPlaceholderForTextInputCell:(BLMTextInputCell *)cell {
    switch ((Section)cell.section) {
        case SectionProjectProperties:
            return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Required (%tu+ characters)", [self minimumInputLengthForTextInputCell:cell]] attributes:[BLMTextInputCell errorAttributes]];

        case SectionSessionConfigurationProperties:
            return [[NSAttributedString alloc] initWithString:@"Optional" attributes:nil];

        case SectionActionButtons:
        case SectionCount: {
            assert(NO);
            return nil;
        }
    }
}


- (NSUInteger)minimumInputLengthForTextInputCell:(BLMTextInputCell *)cell {
    return [self minimumInputLengthForSection:cell.section property:cell.item];
}

#pragma mark BLMTextInputCellDelegate

- (void)didChangeInputForTextInputCell:(BLMTextInputCell *)cell {
    assert([NSThread isMainThread]);
    assert(cell.section < self.properties.count);
    assert(cell.item < self.properties[cell.section].count);

    BOOL wasAllTextInputValid = self.isAllTextInputValid;

    self.properties[cell.section][cell.item] = (cell.textField.text ?: @"");

    if (wasAllTextInputValid != self.isAllTextInputValid) {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:ActionButtonCreateProject inSection:SectionActionButtons]]];
        } completion:nil];
    }
}


- (BOOL)shouldAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    assert([NSThread isMainThread]);
    assert(cell.section < self.properties.count);
    assert(cell.item < self.properties[cell.section].count);
    assert([BLMUtils isString:self.properties[cell.section][cell.item] equalToString:(cell.textField.text ?: @"")]);

    return [self isTextInput:cell.textField.text validForSection:cell.section property:cell.item];
}


- (void)didAcceptInputForTextInputCell:(BLMTextInputCell *)cell {
    assert([NSThread isMainThread]);
    assert(cell.section < self.properties.count);
    assert(cell.item < self.properties[cell.section].count);
    assert([self isTextInput:cell.textField.text validForSection:cell.section property:cell.item]);
    assert([BLMUtils isString:self.properties[cell.section][cell.item] equalToString:(cell.textField.text ?: @"")]);
}

#pragma mark BLMButtonCellDataSource

- (BOOL)isButtonEnabledForButtonCell:(BLMButtonCell *)cell {
    switch ((ActionButton)cell.item) {
        case ActionButtonCreateProject:
            return self.isAllTextInputValid;

        case ActionButtonCancel:
            return YES;

        case ActionButtonCount: {
            assert(NO);
            return NO;
        }
    }
}


- (nullable UIImage *)imageForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state {
    return nil;
}


- (NSAttributedString *)attributedTitleForButtonCell:(BLMButtonCell *)cell forState:(UIControlState)state {
    BLMColorHexCode colorHexValue = ((state == UIControlStateNormal) ? BLMColorHexCodeBlue : BLMColorHexCodePurple);
    NSDictionary *attributes = @{ NSForegroundColorAttributeName:[BLMViewUtils colorForHexCode:colorHexValue] };

    switch ((ActionButton)cell.item) {
        case ActionButtonCreateProject:
            return [[NSAttributedString alloc] initWithString:@"Create Project" attributes:attributes];

        case ActionButtonCancel:
            return [[NSAttributedString alloc] initWithString:@"Cancel" attributes:attributes];

        case ActionButtonCount: {
            assert(NO);
            return nil;
        }
    }
}

#pragma mark BLMButtonCellDelegate

- (void)didFireActionForButtonCell:(BLMButtonCell *)cell {
    switch ((ActionButton)cell.item) {
        case ActionButtonCreateProject:
            [self createProjectFromTextInput];
            break;

        case ActionButtonCancel:
            [self.delegate createProjectControllerDidCancel:self];
            break;

        case ActionButtonCount: {
            assert(NO);
            break;
        }
    }
}

@end
