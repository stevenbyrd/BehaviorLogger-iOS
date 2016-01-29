//
//  BLMProjectDetailController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMProjectDetailController.h"
#import "BLMProjectMenuController.h"
#import "BLMDataManager.h"
#import "BLMProject.h"


@implementation BLMProjectDetailController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor grayColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectMenuControllerDidSelectProject:) name:BLMProjectMenuControllerDidSelectProjectNotification object:nil];
}


- (void)updateContentWithProject:(BLMProject *)project {

}


- (void)handleProjectMenuControllerDidSelectProject:(NSNotification *)notification {
    BLMProject *project = notification.userInfo[BLMProjectMenuControllerSelectedProjectUserInfoKey];
    assert(project != nil);

    [self updateContentWithProject:project];
}

@end
