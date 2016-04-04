//
//  BLMProjectMenuController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMCreateProjectController.h"
#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMProjectDetailController.h"
#import "BLMProjectMenuController.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"


BLMColorHexCode const BLMCreateProjectCellTextColor = BLMColorHexCodeBlue;

static CGFloat const ProjectCellFontSize = 14.0;


typedef NS_ENUM(NSInteger, TableSection) {
    TableSectionProjectList,
    TableSectionCreateProject,
    TableSectionCount
};


#pragma mark

@interface ProjectCell : UITableViewCell

@end


@implementation ProjectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self == nil) {
        return nil;
    }

    self.contentView.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeWhite];
    self.textLabel.font = [UIFont systemFontOfSize:ProjectCellFontSize];

    return self;
}

@end


#pragma mark

@interface CreateProjectCell : UITableViewCell

@property (nonatomic, strong, readonly) UIView *separatorView;

@end


@implementation CreateProjectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self == nil) {
        return nil;
    }

    UIColor *contentColor = [BLMViewUtils colorForHexCode:BLMCreateProjectCellTextColor];

    NSDictionary *textAttributes = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:12.0],
                                      NSParagraphStyleAttributeName : [BLMViewUtils centerAlignedParagraphStyle],
                                      NSForegroundColorAttributeName : contentColor };

    self.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Create New" attributes:textAttributes];
    self.textLabel.numberOfLines = 1;

    _separatorView = [[UIView alloc] initWithFrame:CGRectZero];

    self.separatorView.backgroundColor = contentColor;
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.separatorView];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeHeight equalToConstant:1.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeWidth equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeCenterX equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeTop equalToItem:self.contentView constant:0.0]];

    self.contentView.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeWhite];

    return self;
}

@end


#pragma mark

@interface BLMProjectMenuController () <UITableViewDelegate, UITableViewDataSource, BLMCreateProjectControllerDelegate>

@property (nonatomic, strong) NSUUID *selectedProjectUUID;
@property (nonatomic, copy, readonly) NSMutableArray<NSUUID *> *projectUUIDs;
@property (nonatomic, strong, readonly) UITableView *tableView;

@end


@implementation BLMProjectMenuController

- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUUIDs = [NSMutableArray array];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Projects";

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero];

    [self.tableView registerClass:[ProjectCell class] forCellReuseIdentifier:@"ProjectCell"];
    [self.tableView registerClass:[CreateProjectCell class] forCellReuseIdentifier:@"CreateProjectCell"];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.tableView];
    [self.view addConstraints:[BLMViewUtils constraintsForItem:self.tableView equalToItem:self.view]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelArchiveRestored:) name:BLMDataManagerArchiveRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectCreated:) name:BLMProjectCreatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectDeleted:) name:BLMProjectDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectUpdated:) name:BLMProjectUpdatedNotification object:nil];
}

#pragma mark Internal State

- (void)refreshProjectList {
    assert([NSThread isMainThread]);
    assert(![BLMDataManager sharedManager].isRestoringArchive);

    [self.projectUUIDs removeAllObjects];

    for (BLMProject *project in [BLMDataManager sharedManager].projectEnumerator) {
        [self.projectUUIDs insertObject:project.UUID atIndex:[self insertionIndexForProjectUUID:project.UUID]];
    }

    [self.tableView reloadData];

    if (self.projectUUIDs.count == 0) {
        assert(self.selectedProjectUUID == nil);
        [self showCreateProjectController];
    } else if (self.selectedProjectUUID == nil) {
        [self selectProjectWithUUID:self.projectUUIDs.lastObject];
    }
}


- (NSUInteger)insertionIndexForProjectUUID:(NSUUID *)UUID {
    static NSComparator comparator;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        comparator = ^NSComparisonResult(NSUUID *leftUUID, NSUUID *rightUUID) {
            NSString *leftName = [[BLMDataManager sharedManager] projectForUUID:leftUUID].name;
            NSString *rightName = [[BLMDataManager sharedManager] projectForUUID:rightUUID].name;

            assert(leftName != nil);
            assert(rightName != nil);

            return [leftName compare:rightName];
        };
    });

    return [self.projectUUIDs indexOfObject:UUID inSortedRange:NSMakeRange(0, self.projectUUIDs.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
}


- (void)showCreateProjectController {
    assert([NSThread isMainThread]);

    UINavigationController *detailController = self.splitViewController.viewControllers.lastObject;

    if ([detailController.viewControllers.firstObject isKindOfClass:[BLMCreateProjectController class]]) {
        assert(detailController.viewControllers.count == 1);
        assert(self.selectedProjectUUID == nil);
        return;
    }

    if (self.selectedProjectUUID != nil) {
        assert(detailController.viewControllers.count > 0);
        self.selectedProjectUUID = nil;
    }

    detailController.viewControllers = @[[[BLMCreateProjectController alloc] initWithDelegate:self]];
}


- (void)selectProjectWithUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    assert(UUID != nil);

    if ([BLMUtils isObject:self.selectedProjectUUID equalToObject:UUID]) {
        return;
    }

    UINavigationController *detailController = self.splitViewController.viewControllers.lastObject;
    assert(detailController.viewControllers.count <= 1);

    BLMProject *project = [[BLMDataManager sharedManager] projectForUUID:UUID];
    detailController.viewControllers = @[[[BLMProjectDetailController alloc] initWithProject:project]];

    NSInteger selectedIndex = [self.projectUUIDs indexOfObject:UUID];
    assert(selectedIndex != NSNotFound);

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:TableSectionProjectList];
    UITableViewScrollPosition scrollPosition = ((self.selectedProjectUUID == nil) ? UITableViewScrollPositionBottom : UITableViewScrollPositionNone);

    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:scrollPosition];

    self.selectedProjectUUID = UUID;
}

#pragma mark Event Handling

- (void)handleDataModelArchiveRestored:(NSNotification *)notification {
    [self refreshProjectList];
}


- (void)handleDataModelProjectCreated:(NSNotification *)notification {
    assert([NSThread isMainThread]);

    [self.tableView beginUpdates];

    BLMProject *project = (BLMProject *)notification.object;
    NSUInteger insertionIndex = [self insertionIndexForProjectUUID:project.UUID];

    [self.projectUUIDs insertObject:project.UUID atIndex:insertionIndex];

    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:insertionIndex inSection:TableSectionProjectList]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}


- (void)handleDataModelProjectDeleted:(NSNotification *)notification {
    assert([NSThread isMainThread]);

    BLMProject *project = (BLMProject *)notification.object;
    NSUInteger index = [self.projectUUIDs indexOfObject:project.UUID];

    if (index != NSNotFound) {
        [self.tableView beginUpdates];

        [self.projectUUIDs removeObjectAtIndex:index];

        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:TableSectionProjectList]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }

    if ([BLMUtils isObject:self.selectedProjectUUID equalToObject:project.UUID]) {
        if (self.projectUUIDs.count == 0) {
            [self showCreateProjectController];
        } else {
            [self selectProjectWithUUID:self.projectUUIDs.lastObject];
        }
    }
}


- (void)handleDataModelProjectUpdated:(NSNotification *)notification {
    assert([NSThread isMainThread]);

    BLMProject *project = (BLMProject *)notification.object;
    NSInteger index = [self.projectUUIDs indexOfObject:project.UUID];

    if (index != NSNotFound) {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:TableSectionProjectList]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return TableSectionCount;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;

    switch ((TableSection)section) {
        case TableSectionProjectList:
            rowCount = self.projectUUIDs.count;
            break;

        case TableSectionCreateProject:
            rowCount = 1;
            break;

        case TableSectionCount: {
            assert(NO);
            break;
        }
    }

    return rowCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    switch ((TableSection)indexPath.section) {
        case TableSectionProjectList: {
            ProjectCell *projectCell = [tableView dequeueReusableCellWithIdentifier:@"ProjectCell"];

            NSUUID *UUID = self.projectUUIDs[indexPath.row];
            BLMProject *project = [[BLMDataManager sharedManager] projectForUUID:UUID];
            projectCell.textLabel.text = project.name;

            cell = projectCell;
            break;
        }

        case TableSectionCreateProject: {
            CreateProjectCell *createProjectCell = [tableView dequeueReusableCellWithIdentifier:@"CreateProjectCell"];
            cell = createProjectCell;
            break;
        }

        case TableSectionCount: {
            assert(NO);
            break;
        }
    }

    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    assert(!self.splitViewController.isCollapsed);

    switch ((TableSection)indexPath.section) {
        case TableSectionProjectList:
            assert(indexPath.row < self.projectUUIDs.count);
            [self selectProjectWithUUID:self.projectUUIDs[indexPath.row]];
            break;

        case TableSectionCreateProject:
            [self showCreateProjectController];
            break;
            
        case TableSectionCount: {
            assert(NO);
            break;
        }
    }
}

#pragma mark BLMCreateProjectControllerDelegate

- (void)createProjectController:(BLMCreateProjectController *)controller didCreateProject:(BLMProject *)project {
    assert([self.projectUUIDs indexOfObject:project.UUID] != NSNotFound);
    [self selectProjectWithUUID:project.UUID];
}


- (void)createProjectControllerDidCancel:(BLMCreateProjectController *)controller {
    [self selectProjectWithUUID:self.projectUUIDs.lastObject];
}

@end
