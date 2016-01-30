//
//  BLMEditSchemaController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMSchemaUpdateController.h"
#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMSchema.h"
#import "BLMSession.h"
#import "BLMUtils.h"


@interface BLMSchemaUpdateController ()

@property (nonatomic, strong) BLMSchema *schema;

@end


@implementation BLMSchemaUpdateController

- (instancetype)initWithProject:(BLMProject *)project {
    NSParameterAssert(project != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectUid = project.uid;
    _schema = project.defaultSessionConfiguration.schema;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMProjectUpdatedNotification object:project];

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDoneButtonTapped)];
}


- (void)refreshSchema {
    assert([NSThread isMainThread]);

    BLMProject *project = [[BLMDataManager sharedManager] projectForUid:self.projectUid];
    BLMSchema *schema = project.defaultSessionConfiguration.schema;

    if (![BLMUtils isObject:self.schema equalToObject:schema]) {
        _schema = schema;

        //TODO: reload macro list UI
    }
}

#pragma mark Event Handling

- (void)handleProjectUpdated:(NSNotification *)notification {
    BLMProject *project = (BLMProject *)notification.object;
    assert([BLMUtils isNumber:self.projectUid equalToNumber:project.uid]);

    [self refreshSchema];
}

- (void)handleDoneButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
