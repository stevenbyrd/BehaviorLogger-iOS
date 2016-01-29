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


@interface BLMSchemaUpdateController ()

@property (nonatomic, copy) NSArray *updatedMacroList;

@end


@implementation BLMSchemaUpdateController

- (instancetype)initWithProject:(BLMProject *)project {
    NSParameterAssert(project != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _project = project;
    _updatedMacroList = [project.schema.macros copy];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMDataManagerProjectUpdatedNotification object:self.project];

    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)setProject:(BLMProject *)project {
    NSParameterAssert(project != nil);

    if (self.project == project) {
        assert(NO);
        return;
    }

    if (self.project != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:BLMDataManagerProjectUpdatedNotification object:self.project];
    }

    _project = project;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectUpdated:) name:BLMDataManagerProjectUpdatedNotification object:self.project];
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
    BLMProject *project = notification.object;
    assert([self.project.uid isEqualToNumber:project.uid]);

    self.project = [[BLMDataManager sharedManager] projectForUid:self.project.uid];
    self.updatedMacroList = self.project.schema.macros;
}

@end
