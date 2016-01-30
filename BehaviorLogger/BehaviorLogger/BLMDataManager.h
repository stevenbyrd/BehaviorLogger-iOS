//
//  BLMDataManager.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const BLMDataManagerArchiveRestoredNotification;

extern NSString *const BLMProjectCreatedNotification;
extern NSString *const BLMProjectDeletedNotification;
extern NSString *const BLMProjectUpdatedNotification;

extern NSString *const BLMProjectOldProjectUserInfoKey;
extern NSString *const BLMProjectNewProjectUserInfoKey;


@class BLMProject;
@class BLMSchema;
@class BLMSession;
@class BLMSessionConfiguration;


@interface BLMDataManager : NSObject

@property (nonatomic, assign, readonly, getter=isRestoringArchive) BOOL restoringArchive;

+ (void)initializeWithCompletion:(dispatch_block_t)completion;
+ (instancetype)sharedManager;

- (NSIndexSet *)allProjectUids;
- (BLMProject *)projectForUid:(NSNumber *)uid;

- (void)createProjectWithName:(NSString *)name client:(NSString *)client completion:(void(^)(BLMProject *createdProject, NSError *error))completion;

- (void)updateDefaultSessionConfigurationForProjectUid:(NSNumber *)projectUid configuration:(BLMSessionConfiguration *)configuration;

@end
