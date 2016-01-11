//
//  ProjectMenuController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "ProjectMenuController.h"
#import "DataModelManager.h"
#import "Project.h"


NSString *const ProjectMenuControllerDidSelectProjectNotification = @"ProjectMenuControllerDidSelectProjectNotification";
NSString *const ProjectMenuControllerSelectedProjectUserInfoKey = @"ProjectMenuControllerSelectedProjectUserInfoKey";

float const ProjectCellFontSize = 14.0;


// TODO: TableSectionFilterByName,
typedef NS_ENUM(NSInteger, TableSection) {
    TableSectionProjectList,
    TableSectionCreateProject,
    TableSectionCount
};


#pragma mark

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

@interface ProjectMenuController () <UITextFieldDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, copy, readonly) NSArray<Project *> *projectList;

@end


@implementation ProjectMenuController

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelArchiveRestored:) name:DataModelArchiveRestoredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectCreated:) name:DataModelProjectCreatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectDeleted:) name:DataModelProjectDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelProjectUpdated:) name:DataModelProjectUpdatedNotification object:nil];
}

#pragma mark Internal State

- (void)loadProjectList {
    assert([NSThread isMainThread]);
    assert(![DataModelManager sharedManager].isRestoringArchive);

    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    Project *selectedProject = nil;

    if (selectedIndexPath != nil) {
        switch ((TableSection)selectedIndexPath.section) {
            case TableSectionProjectList:
                selectedProject = self.projectList[selectedIndexPath.row];
                assert(selectedProject != nil);
                break;

            case TableSectionCreateProject:
            case TableSectionCount:
                assert(NO);
                break;
        }

        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
        assert(self.tableView.indexPathsForSelectedRows.count == 0);
    }

    NSIndexSet *finalUidSet = [DataModelManager sharedManager].allProjectUids;
    NSMutableArray<Project *> *finalProjectList = [NSMutableArray array];
    NSMutableArray<NSNumber *> *finalUidList = [NSMutableArray array];

    if (finalUidSet.count > 0) {
        [finalUidSet enumerateIndexesUsingBlock:^(NSUInteger uid, BOOL * _Nonnull stop) {
            [finalUidList addObject:@(uid)];
            [finalProjectList addObject:[[DataModelManager sharedManager] projectForUid:@(uid)]];
        }];
    }

    NSMutableIndexSet *originalUidSet = [NSMutableIndexSet indexSet];
    NSMutableArray *originalUidList = [NSMutableArray array];

    [self.projectList enumerateObjectsUsingBlock:^(Project *project, NSUInteger idx, BOOL * _Nonnull stop) {
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

    if (selectedProject != nil) {
        NSInteger selectedIndex = [finalUidList indexOfObject:selectedProject.uid];

        if (selectedIndex != NSNotFound) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:TableSectionProjectList] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

#pragma mark Event Handling

- (void)handleDataModelArchiveRestored:(NSNotification *)notification {
    [self loadProjectList];
}


- (void)handleDataModelProjectCreated:(NSNotification *)notification {
    [self loadProjectList];
}


- (void)handleDataModelProjectDeleted:(NSNotification *)notification {
    [self loadProjectList];
}


- (void)handleDataModelProjectUpdated:(NSNotification *)notification {
    [self loadProjectList];
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

        [[DataModelManager sharedManager] createProjectWithName:projectName client:client schema:nil sessionByUid:nil completion:^(Project *createdProject, NSError *error) {
            if (error != nil) {
                UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.userInfo[NSLocalizedDescriptionKey] preferredStyle:UIAlertControllerStyleAlert];

                [errorAlertController addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self showCreateProjectAlertControllerWithProjectName:nil client:client];
                }]];

                [self presentViewController:errorAlertController animated:YES completion:nil];
            }
        }];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] removeObserver:projectNameTextFieldDidChangeObserver];
        [[NSNotificationCenter defaultCenter] removeObserver:clientTextFieldDidChangeObserver];
    }];

    void (^textFieldDidChangeBlock)(NSNotification *) = ^(NSNotification * notification) {
        okayAction.enabled = ((alertController.textFields[0].text.length >= ProjectNameMinimumLength)
                              && (alertController.textFields[1].text.length >= ProjectClientMinimumLength));
    };

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = projectName;
        textField.delegate = self;
        textField.placeholder = [NSString stringWithFormat:@"Project Name (minimum of %ld characters)", (long)ProjectNameMinimumLength];
        projectNameTextFieldDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:textField queue:[NSOperationQueue mainQueue] usingBlock:textFieldDidChangeBlock];
    }];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = client;
        textField.delegate = self;
        textField.placeholder = [NSString stringWithFormat:@"Client (minimum of %ld character)", (long)ProjectClientMinimumLength];
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
    TableSection section = indexPath.section;
    
    switch (section) {            
        case TableSectionProjectList: {
            Project *project = self.projectList[indexPath.row];
            NSDictionary *userInfo = @{ ProjectMenuControllerSelectedProjectUserInfoKey:project };
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ProjectMenuControllerDidSelectProjectNotification object:self userInfo:userInfo];
            
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
