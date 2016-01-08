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

@interface ProjectMenuController ()

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, copy, readonly) NSArray<Project *> *projectList;

@end


@implementation ProjectMenuController

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
            //TODO: Push a ProjectCreationController onto splitViewController's detail controller stack
            NSLog(@"");
            break;
        }
            
        case TableSectionCount:
            assert(NO);
            break;
    }
}

@end
