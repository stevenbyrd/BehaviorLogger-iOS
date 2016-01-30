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


float const ProjectCellFontSize = 14.0;


// TODO: TableSectionFilterByName,
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

    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.separatorView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.separatorView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.separatorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.separatorView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:1.0]];

    self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];

    return self;
}

@end


#pragma mark

@interface BLMProjectMenuController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, copy, readonly) NSMutableArray<NSNumber *> *projectUidList;
@property (nonatomic, strong) NSNumber *selectedProjectUid;

@end


@implementation BLMProjectMenuController

- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUidList = [NSMutableArray array];

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
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelArchiveRestored:) name:BLMDataManagerArchiveRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectCreated:) name:BLMProjectCreatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectDeleted:) name:BLMProjectDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectUpdated:) name:BLMProjectUpdatedNotification object:nil];
}

#pragma mark Internal State

- (void)refreshProjectList {
    assert([NSThread isMainThread]);
    assert(![BLMDataManager sharedManager].isRestoringArchive);

    [self.projectUidList removeAllObjects];

    [[BLMDataManager sharedManager].allProjectUids enumerateIndexesUsingBlock:^(NSUInteger uid, BOOL * _Nonnull stop) {
        [self.projectUidList addObject:@(uid)];
    }];

    [self.tableView reloadData];

    if (self.selectedProjectUid == nil) {
        [self showDetailsForProjectUid:self.projectUidList.lastObject];
    }
}

- (void)showDetailsForProjectUid:(NSNumber *)projectUid {
    assert([NSThread isMainThread]);

    UINavigationController *detailController = self.splitViewController.viewControllers.lastObject;

    if ((projectUid == nil) && (self.selectedProjectUid == nil)) {
        assert(detailController.viewControllers.count == 0);
        return;
    }

    if (projectUid == nil) {
        assert(self.selectedProjectUid != nil);
        assert([detailController.topViewController isKindOfClass:[BLMProjectDetailController class]]);

        NSInteger selectedIndex = [self.projectUidList indexOfObject:self.selectedProjectUid];
        assert(selectedIndex != NSNotFound);

        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:TableSectionProjectList];
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];

        detailController.viewControllers = @[];
    } else if (![BLMUtils isNumber:self.selectedProjectUid equalToNumber:projectUid]) {
        assert(detailController.viewControllers.count <= 1);

        NSInteger selectedIndex = [self.projectUidList indexOfObject:projectUid];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:TableSectionProjectList];
        UITableViewScrollPosition scrollPosition = ((self.selectedProjectUid == nil) ? UITableViewScrollPositionBottom : UITableViewScrollPositionNone);
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:scrollPosition];

        BLMProject *project = [[BLMDataManager sharedManager] projectForUid:projectUid];
        detailController.viewControllers = @[[[BLMProjectDetailController alloc] initWithProject:project]];
    }

    self.selectedProjectUid = projectUid;
}

#pragma mark Event Handling

- (void)handleDataModelArchiveRestored:(NSNotification *)notification {
    [self refreshProjectList];
}


- (void)handleDataModelProjectCreated:(NSNotification *)notification {
    assert([NSThread isMainThread]);

    BLMProject *project = (BLMProject *)notification.object;
    NSNumber *projectUid = project.uid;
    assert(![self.projectUidList containsObject:projectUid]);

    [self.tableView beginUpdates];
    [self.projectUidList addObject:projectUid];

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(self.projectUidList.count - 1) inSection:TableSectionProjectList];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}


- (void)handleDataModelProjectDeleted:(NSNotification *)notification {
    assert([NSThread isMainThread]);

    BLMProject *project = (BLMProject *)notification.object;
    NSNumber *projectUid = project.uid;
    NSInteger index = [self.projectUidList indexOfObject:projectUid];

    if (index != NSNotFound) {
        [self.tableView beginUpdates];
        [self.projectUidList removeObjectAtIndex:index];

        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:TableSectionProjectList];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }

    if (self.selectedProjectUid == projectUid) {
        [self showDetailsForProjectUid:nil];
    }
}


- (void)handleDataModelProjectUpdated:(NSNotification *)notification {
    assert([NSThread isMainThread]);

    BLMProject *project = (BLMProject *)notification.object;
    NSInteger index = [self.projectUidList indexOfObject:project.uid];

    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:TableSectionProjectList];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
                assert([BLMUtils isObject:self.projectUidList.lastObject equalToObject:createdProject.uid]);

                [self showDetailsForProjectUid:createdProject.uid];
            }
        }];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] removeObserver:projectNameTextFieldDidChangeObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:clientTextFieldDidChangeObserver];

        if (self.selectedProjectUid != nil) {
            NSInteger index = [self.projectUidList indexOfObject:self.selectedProjectUid];
            assert(index != NSNotFound);

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:TableSectionProjectList];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];

    void (^textFieldDidChangeBlock)(NSNotification *) = ^(NSNotification * notification) {
        okayAction.enabled = ((alertController.textFields[0].text.length >= BLMProjectNameMinimumLength)
                              && (alertController.textFields[1].text.length >= BLMProjectClientMinimumLength));
    };

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = projectName;
        textField.delegate = self;
        textField.placeholder = [NSString stringWithFormat:@"Project Name (minimum of %ld characters)", (long)BLMProjectNameMinimumLength];
        projectNameTextFieldDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:textField queue:[NSOperationQueue mainQueue] usingBlock:textFieldDidChangeBlock];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = client;
        textField.delegate = self;
        textField.placeholder = [NSString stringWithFormat:@"Client (minimum of %ld character)", (long)BLMProjectClientMinimumLength];
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
        case TableSectionProjectList:
            rowCount = self.projectUidList.count;
            break;

        case TableSectionCreateProject:
            rowCount = 1;
            break;

        case TableSectionCount:
            assert(NO);
            break;
    }

    return rowCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    TableSection section = indexPath.section;

    switch (section) {
        case TableSectionProjectList: {
            ProjectCell *projectCell = [tableView dequeueReusableCellWithIdentifier:@"ProjectCell"];

            NSNumber *projectUid = self.projectUidList[indexPath.row];
            BLMProject *project = [[BLMDataManager sharedManager] projectForUid:projectUid];
            projectCell.textLabel.text = project.name;

            cell = projectCell;
            break;
        }

        case TableSectionCreateProject: {
            CreateProjectCell *createProjectCell = [tableView dequeueReusableCellWithIdentifier:@"CreateProjectCell"];
            cell = createProjectCell;
            break;
        }

        case TableSectionCount:
            assert(NO);
            break;
    }

    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    assert(!self.splitViewController.isCollapsed);

    TableSection section = indexPath.section;

    switch (section) {
        case TableSectionProjectList: {
            NSNumber *projectUid = self.projectUidList[indexPath.row];
            [self showDetailsForProjectUid:projectUid];
            break;
        }

        case TableSectionCreateProject: {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            [self showCreateProjectAlertControllerWithProjectName:nil client:nil];
            break;
        }
            
        case TableSectionCount:
            assert(NO);
            break;
    }
}

@end
