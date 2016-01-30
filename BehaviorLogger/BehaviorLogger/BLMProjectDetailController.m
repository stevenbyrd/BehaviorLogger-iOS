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
#import "BLMUtils.h"


@implementation BLMProjectDetailController

- (instancetype)initWithProject:(BLMProject *)project {
    NSParameterAssert(project != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUid = project.uid;

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor lightGrayColor];

    BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:project];
}


#pragma mark Event Handling

- (void)handleProjectUpdated:(NSNotification *)notification {
    BLMProject *project = (BLMProject *)notification.object;
    assert([BLMUtils isNumber:self.projectUid equalToNumber:project.uid]);

    //TODO: Update UI
}

@end
