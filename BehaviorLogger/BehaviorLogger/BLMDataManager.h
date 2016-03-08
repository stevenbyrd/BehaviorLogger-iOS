//
//  BLMDataManager.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLMBehavior.h"
#import "BLMProject.h"
#import "BLMSession.h"
#import "BLMSessionConfiguration.h"


extern NSString *const BLMDataManagerArchiveRestoredNotification;

extern NSString *const BLMDataManagerProjectErrorDomain;
extern NSString *const BLMDataManagerBehaviorErrorDomain;


@interface BLMDataManager : NSObject

#pragma Lifecycle

@property (nonatomic, assign, readonly, getter=isRestoringArchive) BOOL restoringArchive;

+ (void)initializeWithCompletion:(dispatch_block_t)completion;
+ (instancetype)sharedManager;

#pragma Project State

- (NSEnumerator<NSUUID *> *)projectUUIDEnumerator;
- (BLMProject *)projectForUUID:(NSUUID *)UUID;
- (void)createProjectWithName:(NSString *)name client:(NSString *)client completion:(void(^)(BLMProject *project, NSError *error))completion;
- (void)updateProjectForUUID:(NSUUID *)UUID property:(BLMProjectProperty)property value:(id)value completion:(void(^)(BLMProject *updatedProject, NSError *error))completion;
- (void)deleteProjectForUUID:(NSUUID *)UUID completion:(void(^)(NSError *error))completion;

#pragma Behavior State

- (NSEnumerator<NSUUID *> *)behaviorUUIDEnumerator;
- (BLMBehavior *)behaviorForUUID:(NSUUID *)UUID;
- (void)createBehaviorWithName:(NSString *)name continuous:(BOOL)continuous completion:(void(^)(BLMBehavior *behavior, NSError *error))completion;
- (void)updateBehaviorForUUID:(NSUUID *)UUID property:(BLMBehaviorProperty)property value:(id)value completion:(void(^)(BLMBehavior *updatedBehavior, NSError *error))completion;
- (void)deleteBehaviorForUUID:(NSUUID *)UUID completion:(void(^)(NSError *error))completion;

#pragma mark Session Configuration State

- (NSEnumerator<NSUUID *> *)sessionConfigurationUUIDEnumerator;
- (BLMSessionConfiguration *)sessionConfigurationForUUID:(NSUUID *)UUID;
- (void)createSessionConfigurationWithCondition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(NSArray<NSUUID *> *)behaviorUUIDs completion:(void(^)(BLMSessionConfiguration *sessionConfiguration, NSError *error))completion;
- (void)updateSessionConfigurationForUUID:(NSUUID *)UUID property:(BLMSessionConfigurationProperty)property value:(id)value completion:(void(^)(BLMSessionConfiguration *updatedSessionConfiguration, NSError *error))completion;
- (void)deleteSessionConfigurationForUUID:(NSUUID *)UUID completion:(void(^)(NSError *error))completion;

@end
