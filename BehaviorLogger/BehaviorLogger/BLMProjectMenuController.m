//
//  BLMProjectMenuController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMProjectDetailController.h"
#import "BLMProjectMenuController.h"
#import "BLMUtils.h"
#import "BLMViewUtils.h"


float const ProjectCellFontSize = 14.0;


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

    self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
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

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *textAttributes = @{ NSForegroundColorAttributeName : [UIColor darkTextColor], NSFontAttributeName : [UIFont boldSystemFontOfSize:12.0], NSParagraphStyleAttributeName : paragraphStyle};

    self.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Create New" attributes:textAttributes];
    self.textLabel.numberOfLines = 1;

    _separatorView = [[UIView alloc] initWithFrame:CGRectZero];

    self.separatorView.backgroundColor = [UIColor blueColor];
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.separatorView];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeHeight equalToConstant:1.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeWidth equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeCenterX equalToItem:self.contentView constant:0.0]];
    [self.contentView addConstraint:[BLMViewUtils constraintWithItem:self.separatorView attribute:NSLayoutAttributeTop equalToItem:self.contentView constant:0.0]];

    self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];

    return self;
}

@end


#pragma mark

@interface BLMProjectMenuController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, copy, readonly) NSMutableArray<NSUUID *> *projectUUIDs;
@property (nonatomic, strong) NSUUID *selectedProjectUUID;

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

    _tableView = [[UITableView alloc] init];

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
    [self.projectUUIDs addObjectsFromArray:[BLMDataManager sharedManager].projectUUIDEnumerator.allObjects];

    [self.projectUUIDs sortUsingComparator:^NSComparisonResult(NSUUID *leftUUID, NSUUID *rightUUID) {
        return [[[BLMDataManager sharedManager] projectForUUID:leftUUID].name compare:[[BLMDataManager sharedManager] projectForUUID:rightUUID].name];
    }];

    [self.tableView reloadData];

    if (self.selectedProjectUUID == nil) {
        [self showDetailsForProjectWithUUID:self.projectUUIDs.lastObject];
    }
}

- (void)showDetailsForProjectWithUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);

    UINavigationController *detailController = self.splitViewController.viewControllers.lastObject;

    if ((UUID == nil) && (self.selectedProjectUUID == nil)) {
        assert(detailController.viewControllers.count == 0);
        return;
    }

    if (UUID == nil) {
        assert(self.selectedProjectUUID != nil);
        assert([detailController.topViewController isKindOfClass:[BLMProjectDetailController class]]);

        NSInteger selectedIndex = [self.projectUUIDs indexOfObject:self.selectedProjectUUID];
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:TableSectionProjectList];

        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];

        detailController.viewControllers = @[];
    } else if (![BLMUtils isObject:self.selectedProjectUUID equalToObject:UUID]) {
        assert(detailController.viewControllers.count <= 1);

        NSInteger selectedIndex = [self.projectUUIDs indexOfObject:UUID];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:TableSectionProjectList];
        UITableViewScrollPosition scrollPosition = ((self.selectedProjectUUID == nil) ? UITableViewScrollPositionBottom : UITableViewScrollPositionNone);

        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:scrollPosition];

        BLMProject *project = [[BLMDataManager sharedManager] projectForUUID:UUID];
        detailController.viewControllers = @[[[BLMProjectDetailController alloc] initWithProject:project]];
    }

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
    [self.projectUUIDs addObject:project.UUID];

    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:(self.projectUUIDs.count - 1) inSection:TableSectionProjectList]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}


- (void)handleDataModelProjectDeleted:(NSNotification *)notification {
    assert([NSThread isMainThread]);

    BLMProject *project = (BLMProject *)notification.object;
    NSInteger index = [self.projectUUIDs indexOfObject:project.UUID];

    if (index != NSNotFound) {
        [self.tableView beginUpdates];
        
        [self.projectUUIDs removeObjectAtIndex:index];

        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:TableSectionProjectList]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }

    if ([BLMUtils isObject:self.selectedProjectUUID equalToObject:project.UUID]) {
        [self showDetailsForProjectWithUUID:nil];
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

#pragma mark Create Project

- (void)showCreateProjectAlertControllerWithProjectName:(NSString *)projectName client:(NSString *)client {
    assert([NSThread isMainThread]);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Create New Project" message:@"Enter a the new project's name and client." preferredStyle:UIAlertControllerStyleAlert];

    __block id projectNameTextFieldDidChangeObserver = nil;
    __block id clientTextFieldDidChangeObserver = nil;

    UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] removeObserver:projectNameTextFieldDidChangeObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:clientTextFieldDidChangeObserver];

        UITextField *projectNameTextField = alertController.textFields[0];
        NSString *projectName = projectNameTextField.text;

        UITextField *clientTextField = alertController.textFields[1];
        NSString *client = clientTextField.text;

        [[BLMDataManager sharedManager] createProjectWithName:projectName client:client completion:^(BLMProject *createdProject, NSError *error) {
            if (error != nil) {
                UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.userInfo[NSLocalizedDescriptionKey] preferredStyle:UIAlertControllerStyleAlert];

                [errorAlertController addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self showCreateProjectAlertControllerWithProjectName:nil client:client];
                }]];

                [self presentViewController:errorAlertController animated:YES completion:nil];
            } else {
                assert(createdProject != nil);
                assert([BLMUtils isObject:self.projectUUIDs.lastObject equalToObject:createdProject.UUID]);

                [self showDetailsForProjectWithUUID:createdProject.UUID];
            }
        }];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] removeObserver:projectNameTextFieldDidChangeObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:clientTextFieldDidChangeObserver];

        if (self.selectedProjectUUID != nil) {
            NSInteger index = [self.projectUUIDs indexOfObject:self.selectedProjectUUID];
            assert(index != NSNotFound);

            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:TableSectionProjectList] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];

    void (^textFieldDidChangeBlock)(NSNotification *) = ^(NSNotification * notification) {
        okayAction.enabled = ((alertController.textFields[0].text.length >= BLMProjectNameMinimumLength)
                              && (alertController.textFields[1].text.length >= BLMProjectClientMinimumLength));
    };

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = projectName;
        textField.delegate = self;
        textField.placeholder = [NSString stringWithFormat:@"Project Name (%ld characters minimum)", (long)BLMProjectNameMinimumLength];
        projectNameTextFieldDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:textField queue:[NSOperationQueue mainQueue] usingBlock:textFieldDidChangeBlock];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = client;
        textField.delegate = self;
        textField.placeholder = [NSString stringWithFormat:@"Client (%ld characters minimum)", (long)BLMProjectClientMinimumLength];
        clientTextFieldDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:textField queue:[NSOperationQueue mainQueue] usingBlock:textFieldDidChangeBlock];
    }];

    [alertController addAction:okayAction];
    [alertController addAction:cancelAction];

    okayAction.enabled = NO;

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return NO;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return TableSectionCount;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;

    switch ((TableSection)section) {
        case TableSectionProjectList: {
            rowCount = self.projectUUIDs.count;
            break;
        }

        case TableSectionCreateProject: {
            rowCount = 1;
            break;
        }

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
        case TableSectionProjectList: {
            NSUUID *UUID = self.projectUUIDs[indexPath.row];
            [self showDetailsForProjectWithUUID:UUID];
            break;
        }

        case TableSectionCreateProject: {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            [self showCreateProjectAlertControllerWithProjectName:nil client:nil];
            break;
        }
            
        case TableSectionCount: {
            assert(NO);
            break;
        }
    }
}

@end
