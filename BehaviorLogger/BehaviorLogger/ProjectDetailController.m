//
//  ProjectDetailController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "ProjectDetailController.h"
#import "ProjectMenuController.h"
#import "DataModelManager.h"
#import "Project.h"


@implementation ProjectDetailController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor grayColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectMenuControllerDidSelectProject:) name:ProjectMenuControllerDidSelectProjectNotification object:nil];
}


- (void)updateContentWithProject:(Project *)project {
    
}


- (void)handleProjectMenuControllerDidSelectProject:(NSNotification *)notification {
    Project *project = notification.userInfo[ProjectMenuControllerSelectedProjectUserInfoKey];
    assert(project != nil);
    
    [self updateContentWithProject:project];
}

@end
