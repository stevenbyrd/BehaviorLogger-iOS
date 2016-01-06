//
//  ProjectManager.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const DataModelManagerRestoredArchivedStateNotification;
extern NSString *const ProjectUpdatedNotification;


@class Project;
@class Schema;


@interface DataModelManager : NSObject

@property (nonatomic, assign, readonly, getter=isRestoringArchive) BOOL restoringArchive;

+ (void)initializeWithCompletion:(dispatch_block_t)completion;
+ (instancetype)sharedManager;

- (NSSet<NSNumber *> *)projectUidSet;
- (Project *)projectForUid:(NSNumber *)uid;

- (void)updateSchemaForProjectUid:(NSNumber *)projectUid toSchema:(Schema *)schema;

@end
