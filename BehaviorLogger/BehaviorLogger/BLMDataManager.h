//
//  BLMDataManager.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const BLMDataManagerArchiveRestoredNotification;

extern NSString *const BLMDataManagerProjectCreatedNotification;
extern NSString *const BLMDataManagerProjectDeletedNotification;
extern NSString *const BLMDataManagerProjectUpdatedNotification;


@class BLMProject;
@class BLMSchema;
@class BLMSession;


@interface BLMDataManager : NSObject

@property (nonatomic, assign, readonly, getter=isRestoringArchive) BOOL restoringArchive;

+ (void)initializeWithCompletion:(dispatch_block_t)completion;
+ (instancetype)sharedManager;

- (NSIndexSet *)allProjectUids;
- (BLMProject *)projectForUid:(NSNumber *)uid;

- (void)createProjectWithName:(NSString *)name client:(NSString *)client schema:(BLMSchema *)schema sessionByUid:(NSDictionary<NSNumber *, BLMSession *> *)sessionByUid completion:(void(^)(BLMProject *createdProject, NSError *error))completion;

- (void)updateSchemaForProjectUid:(NSNumber *)projectUid toSchema:(BLMSchema *)schema;

@end
