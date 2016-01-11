//
//  EditSchemaController.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "SchemaUpdateController.h"
#import "DataModelManager.h"
#import "Project.h"
#import "Schema.h"


@interface SchemaUpdateController ()

@property (nonatomic, copy) NSArray *updatedMacroList;

@end


@implementation SchemaUpdateController

- (instancetype)initWithProject:(Project *)project {
    NSParameterAssert(project != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _project = project;
    _updatedMacroList = [project.schema.macros copy];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:DataModelProjectUpdatedNotification object:self.project];

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)setProject:(Project *)project {
    NSParameterAssert(project != nil);

    if (self.project == project) {
        assert(NO);
        return;
    }

    if (self.project != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:DataModelProjectUpdatedNotification object:self.project];
    }

    _project = project;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:DataModelProjectUpdatedNotification object:self.project];
}


- (void)setUpdatedMacroList:(NSArray *)updatedMacroList {
    NSParameterAssert(updatedMacroList != nil);

    if (self.updatedMacroList == updatedMacroList) {
        assert(NO);
        return;
    }

    _updatedMacroList = [updatedMacroList copy];

    // TODO: reload table
}

#pragma Event Handling

- (void)handleProjectUpdated:(NSNotification *)notification {
    Project *project = notification.object;
    assert([self.project.uid isEqualToNumber:project.uid]);

    self.project = [[DataModelManager sharedManager] projectForUid:self.project.uid];
    self.updatedMacroList = self.project.schema.macros;
}

@end
