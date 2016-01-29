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

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.textLabel.text = nil;
    self.textLabel.font = [ProjectCell fontForSelected:NO];
}

- (void)setSelected:(BOOL)selected {
    super.selected = selected;

    self.textLabel.font = [ProjectCell fontForSelected:selected];
}

+ (UIFont *)fontForSelected:(BOOL)selected {
    return (selected ? [UIFont boldSystemFontOfSize:ProjectCellFontSize] : [UIFont systemFontOfSize:ProjectCellFontSize]);
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
@property (nonatomic, copy, readonly) NSArray<BLMProject *> *projectList;
@property (nonatomic, strong) NSNumber *selectedProjectUid;

@end


@implementation BLMProjectMenuController

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectCreated:) name:BLMDataManagerProjectCreatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectDeleted:) name:BLMDataManagerProjectDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectUpdated:) name:BLMDataManagerProjectUpdatedNotification object:nil];
}

#pragma mark Internal State

- (void)refreshProjectList {
    assert([NSThread isMainThread]);
    assert(![BLMDataManager sharedManager].isRestoringArchive);

    if (self.selectedProjectUid != nil) {
        NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
    }

    NSIndexSet *finalUidSet = [BLMDataManager sharedManager].allProjectUids;
    NSMutableArray<BLMProject *> *finalProjectList = [NSMutableArray array];
    NSMutableArray<NSNumber *> *finalUidList = [NSMutableArray array];

    if (finalUidSet.count > 0) {
        [finalUidSet enumerateIndexesUsingBlock:^(NSUInteger uid, BOOL * _Nonnull stop) {
            [finalUidList addObject:@(uid)];
            [finalProjectList addObject:[[BLMDataManager sharedManager] projectForUid:@(uid)]];
        }];
    }

    NSMutableIndexSet *originalUidSet = [NSMutableIndexSet indexSet];
    NSMutableArray *originalUidList = [NSMutableArray array];

    [self.projectList enumerateObjectsUsingBlock:^(BLMProject *project, NSUInteger idx, BOOL * _Nonnull stop) {
        [originalUidSet addIndex:project.uid.integerValue];
        [originalUidList addObject:project.uid];
    }];

    NSMutableIndexSet *deletedUidSet = [originalUidSet mutableCopy];
    [deletedUidSet removeIndexes:finalUidSet];

    NSMutableIndexSet *insertedUidSet = [finalUidSet mutableCopy];
    [insertedUidSet removeIndexes:originalUidSet];

    NSMutableIndexSet *updatedUidSet = [finalUidSet mutableCopy];
    [updatedUidSet removeIndexes:deletedUidSet];
    [updatedUidSet removeIndexes:insertedUidSet];

    NSArray *(^buildIndexPathList)(NSIndexSet *, NSArray *) = ^NSArray *(NSIndexSet *uidSet, NSArray *sourceUidList) {
        NSMutableArray *indexPathList = [NSMutableArray array];

        [uidSet enumerateIndexesUsingBlock:^(NSUInteger uid, BOOL * _Nonnull stop) {
            NSInteger row = [sourceUidList indexOfObject:@(uid)];
            assert(row != NSNotFound);

            [indexPathList addObject:[NSIndexPath indexPathForRow:row inSection:TableSectionProjectList]];
        }];

        return indexPathList;
    };

    [self.tableView beginUpdates];

    NSArray *deletedIndexPaths = buildIndexPathList(deletedUidSet, originalUidList);
    [self.tableView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationNone];

    NSArray *updatedIndexPaths = buildIndexPathList(updatedUidSet, originalUidList);
    [self.tableView reloadRowsAtIndexPaths:updatedIndexPaths withRowAnimation:UITableViewRowAnimationNone];

    NSArray *insertedIndexPaths = buildIndexPathList(insertedUidSet, finalUidList);
    [self.tableView insertRowsAtIndexPaths:insertedIndexPaths withRowAnimation:UITableViewRowAnimationNone];

    _projectList = [finalProjectList copy];

    [self.tableView endUpdates];

    UINavigationController *detailController = self.splitViewController.viewControllers.lastObject;

    if (self.projectList.count == 0) { // Remove the BLMProjectDetailController for the previously selected project, if present
        [self selectProject:nil];
        assert(self.selectedProjectUid == nil);
    }

    if (self.selectedProjectUid == nil) { // Automatically select the first project in the list if nothing has been selected and there are projects available
        self.selectedProjectUid = self.projectList.firstObject.uid;
    }

    if (self.selectedProjectUid != nil) {
        assert(self.projectList.count > 0);

        NSInteger selectedIndex = [finalUidList indexOfObject:self.selectedProjectUid];

        if (selectedIndex == NSNotFound) { // If the previously selected project is no longer available, automatically select the first listed project
            self.selectedProjectUid = self.projectList.firstObject.uid;
            assert(self.selectedProjectUid != nil);

            selectedIndex = 0;
        }

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:TableSectionProjectList];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];

        BLMProjectDetailController *projectDetailController = detailController.viewControllers.firstObject;
        assert(projectDetailController == detailController.topViewController);

        [self selectProject:[[BLMDataManager sharedManager] projectForUid:self.selectedProjectUid]];
    }
}

- (void)selectProject:(BLMProject *)project {
    assert([NSThread isMainThread]);

    UINavigationController *detailController = self.splitViewController.viewControllers.lastObject;

    if ((project == nil) && (self.selectedProjectUid == nil)) {
        assert(detailController.viewControllers.count == 0);
        return;
    }

    if ((project == nil) || ![self.selectedProjectUid isEqualToNumber:project.uid]) {
        assert(detailController.viewControllers.count <= 1);
        detailController.viewControllers = @[[[BLMProjectDetailController alloc] initWithProject:project]];

        self.selectedProjectUid = project.uid;
    }
}

#pragma mark Event Handling

- (void)handleDataModelArchiveRestored:(NSNotification *)notification {
    [self refreshProjectList];
}


- (void)handleDataModelProjectCreated:(NSNotification *)notification {
    [self refreshProjectList];
}


- (void)handleDataModelProjectDeleted:(NSNotification *)notification {
    [self refreshProjectList];
}


- (void)handleDataModelProjectUpdated:(NSNotification *)notification {
    [self refreshProjectList];
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

        [[BLMDataManager sharedManager] createProjectWithName:projectName client:client schema:nil sessionByUid:nil completion:^(BLMProject *createdProject, NSError *error) {
            if (error != nil) {
                UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.userInfo[NSLocalizedDescriptionKey] preferredStyle:UIAlertControllerStyleAlert];

                [errorAlertController addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self showCreateProjectAlertControllerWithProjectName:nil client:client];
                }]];

                [self presentViewController:errorAlertController animated:YES completion:nil];
            } else {
                assert(createdProject != nil);
                assert([self.projectList.lastObject isEqual:createdProject]);

                self.selectedProjectUid = createdProject.uid;

                NSInteger selectedIndex = [self.projectList indexOfObject:createdProject];
                assert(selectedIndex != NSNotFound);

                NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:TableSectionProjectList];
                [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];

                UINavigationController *detailController = self.splitViewController.viewControllers.lastObject;
                assert(detailController.viewControllers.count <= 1);

                detailController.viewControllers = @[[[BLMProjectDetailController alloc] initWithProject:createdProject]];
            }
        }];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] removeObserver:projectNameTextFieldDidChangeObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:clientTextFieldDidChangeObserver];
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
            rowCount = self.projectList.count;
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
            projectCell.textLabel.text = self.projectList[indexPath.row].name;
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
            [self selectProject:self.projectList[indexPath.row]];
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
