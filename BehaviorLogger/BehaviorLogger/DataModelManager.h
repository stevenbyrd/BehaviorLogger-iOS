//
//  ProjectManager.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const DataModelArchiveRestoredNotification;

extern NSString *const DataModelProjectCreatedNotification;
extern NSString *const DataModelProjectDeletedNotification;
extern NSString *const DataModelProjectUpdatedNotification;


@class Project;
@class Schema;
@class Session;


@interface DataModelManager : NSObject

@property (nonatomic, assign, readonly, getter=isRestoringArchive) BOOL restoringArchive;

+ (void)initializeWithCompletion:(dispatch_block_t)completion;
+ (instancetype)sharedManager;

- (NSIndexSet *)allProjectUids;
- (Project *)projectForUid:(NSNumber *)uid;

- (void)createProjectWithName:(NSString *)name client:(NSString *)client schema:(Schema *)schema sessionByUid:(NSDictionary<NSNumber *, Session *> *)sessionByUid completion:(void(^)(Project *createdProject, NSError *error))completion;

- (void)updateSchemaForProjectUid:(NSNumber *)projectUid toSchema:(Schema *)schema;

@end
