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


extern NSString *__nonnull const BLMDataManagerArchiveRestoredNotification;

extern NSString *__nonnull const BLMDataManagerProjectErrorDomain;
extern NSString *__nonnull const BLMDataManagerBehaviorErrorDomain;


#pragma mark

@interface BLMModelObjectEnumerator<ObjectType> : NSEnumerator<ObjectType>

- (nonnull instancetype)initWithUUIDEnumerator:(nonnull NSEnumerator<NSUUID *> *)UUIDEnumerator objectRetrievalBlock:(__nonnull ObjectType(^__nonnull)(NSUUID *__nonnull UUID))objectRetrievalBlock;

@end


#pragma mark

@interface BLMDataManager : NSObject

#pragma Lifecycle

@property (nonatomic, assign, readonly, getter=isRestoringArchive) BOOL restoringArchive;

+ (void)initializeWithCompletion:(nullable dispatch_block_t)completion;
+ (nonnull instancetype)sharedManager;

#pragma Project State

@property (nonnull, nonatomic, copy, readonly) NSSet<NSString *> *projectNameSet;

- (nonnull BLMProject *)projectForUUID:(nonnull NSUUID *)UUID;
- (nonnull NSEnumerator<BLMProject *> *)projectEnumerator;
- (void)createProjectWithName:(nonnull NSString *)name client:(nonnull NSString *)client sessionConfigurationUUID:(nonnull NSUUID *)sessionConfigurationUUID completion:(nullable void(^)(BLMProject *__nullable project, NSError *__nullable error))completion;
- (void)updateProjectForUUID:(nonnull NSUUID *)UUID property:(BLMProjectProperty)property value:(nullable id)value completion:(nullable void(^)(BLMProject *__nullable updatedProject, NSError *__nullable error))completion;
- (void)deleteProjectForUUID:(nonnull NSUUID *)UUID completion:(nullable void(^)(NSError *__nullable error))completion;

#pragma Behavior State

- (nonnull BLMBehavior *)behaviorForUUID:(nonnull NSUUID *)UUID;
- (nonnull NSEnumerator<BLMBehavior *> *)behaviorEnumerator;
- (void)createBehaviorWithName:(nonnull NSString *)name continuous:(BOOL)continuous completion:(nullable void(^)(BLMBehavior *__nullable behavior, NSError *__nullable error))completion;
- (void)updateBehaviorForUUID:(nonnull NSUUID *)UUID property:(BLMBehaviorProperty)property value:(nullable id)value completion:(nullable void(^)(BLMBehavior *__nullable updatedBehavior, NSError *__nullable error))completion;
- (void)deleteBehaviorForUUID:(nonnull NSUUID *)UUID completion:(void(^__nullable)(NSError *__nullable error))completion;

#pragma mark Session Configuration State

- (nonnull BLMSessionConfiguration *)sessionConfigurationForUUID:(nonnull NSUUID *)UUID;
- (nonnull NSEnumerator<BLMSessionConfiguration *> *)sessionConfigurationEnumerator;
- (void)createSessionConfigurationWithCondition:(nullable NSString *)condition location:(nullable NSString *)location therapist:(nullable NSString *)therapist observer:(nullable NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(nonnull NSArray<NSUUID *> *)behaviorUUIDs completion:(nullable void(^)(BLMSessionConfiguration *__nullable sessionConfiguration, NSError *__nullable error))completion;
- (void)updateSessionConfigurationForUUID:(nonnull NSUUID *)UUID property:(BLMSessionConfigurationProperty)property value:(nullable id)value completion:(nullable void(^)(BLMSessionConfiguration *__nullable updatedSessionConfiguration, NSError *__nullable error))completion;
- (void)deleteSessionConfigurationForUUID:(nonnull NSUUID *)UUID completion:(nullable void(^)(NSError *__nullable error))completion;

@end
