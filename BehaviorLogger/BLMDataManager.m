//
//  BLMDataManager.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMSession.h"
#import "BLMUtils.h"
#import "NSSet+BLMAdditions.h"
#import "NSOrderedSet+BLMAdditions.h"

#import <objc/runtime.h>


#pragma mark Constants

NSString *const BLMDataManagerProjectErrorDomain = @"com.3bird.BehaviorLogger.Project";
NSString *const BLMDataManagerBehaviorErrorDomain = @"com.3bird.BehaviorLogger.Behavior";


static NSString *const ArchiveFileName = @"project.dat";
static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


static inline NSString *ArchiveDirectory() {
    static NSString *archiveDirectory = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        NSString *libraryDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
        archiveDirectory = [NSString pathWithComponents:@[libraryDirectory, @"Application Support", @"com.3bird.BehaviorLogger", @"Archives"]];
    });

    return archiveDirectory;
}


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@interface BLMDataManager ()

@property (nonatomic, copy, readwrite) NSSet<NSString *> *projectNameSet;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMProject *> *projectByUUID;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMBehavior *> *behaviorByUUID;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMSession *> *sessionByUUID;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMSessionConfiguration *> *sessionConfigurationByUUID;
@property (nonatomic, strong, readonly) NSOperationQueue *archiveQueue;

@end


@implementation BLMDataManager

+ (void)initializeWithCompletion:(dispatch_block_t)completion {
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        [[BLMDataManager sharedManager] restoreArchivedStateWithCompletion:completion];
    });
}


+ (instancetype)sharedManager {
    assert([NSThread isMainThread]);
    
    static BLMDataManager *sharedManager = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        sharedManager = [[BLMDataManager alloc] init];
    });

    return sharedManager;
}


- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _projectByUUID = [NSMutableDictionary dictionary];
    _behaviorByUUID = [NSMutableDictionary dictionary];
    _sessionConfigurationByUUID = [NSMutableDictionary dictionary];

    _archiveQueue = [[NSOperationQueue alloc] init];
    _archiveQueue.name = [NSString stringWithFormat:@"%@ - Archive Queue", NSStringFromClass([self class])];
    _archiveQueue.qualityOfService = NSOperationQualityOfServiceBackground;
    _archiveQueue.maxConcurrentOperationCount = 1;

    return self;
}

#pragma mark BLMProject

- (NSSet<NSString *> *)projectNameSet {
    assert([NSThread isMainThread]);

    if (_projectNameSet == nil) {
        NSMutableSet *projectNameSet = [NSMutableSet set];

        for (BLMProject *project in self.projectEnumerator) {
            [projectNameSet addObject:project.name];
        }

        self.projectNameSet = projectNameSet;
    }

    assert(self.projectByUUID.count == _projectNameSet.count);
    
    return _projectNameSet;
}


- (BLMProject *)projectForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    return self.projectByUUID[UUID];
}


- (NSEnumerator<BLMProject *> *)projectEnumerator {
    assert([NSThread isMainThread]);
    return self.projectByUUID.objectEnumerator;
}


- (void)createProjectWithName:(NSString *)name client:(NSString *)client sessionConfigurationUUID:(NSUUID *)sessionConfigurationUUID completion:(void(^)(BLMProject *project, NSError *error))completion {
    assert([NSThread isMainThread]);

    assert(![self.projectNameSet containsObject:name]);
    self.projectNameSet = [self.projectNameSet setByAddingObject:name];

    BLMProject *project = [[BLMProject alloc] initWithUUID:[NSUUID UUID] name:name client:client sessionConfigurationUUID:sessionConfigurationUUID sessionUUIDs:nil];
    self.projectByUUID[project.UUID] = project;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMProjectUpdatedProjectUserInfoKey:project };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectCreatedNotification object:project userInfo:userInfo];

    if (completion != nil) {
        completion(project, nil);
    }
}


- (void)updateProjectForUUID:(NSUUID *)UUID property:(BLMProjectProperty)property value:(id)value completion:(void(^)(BLMProject *updatedProject, NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMProject *original = self.projectByUUID[UUID];
    BLMProject *updated = [original copyWithUpdatedValuesByProperty:@{ @(property):(value ?: [NSNull null]) }];

    if ([BLMUtils isObject:original equalToObject:updated]) {
        if (completion != nil) {
            completion(original, nil);
        }
        return;
    }

    if (property == BLMProjectPropertyName) {
        assert([self.projectNameSet containsObject:original.name]);
        assert(![self.projectNameSet containsObject:updated.name]);

        NSMutableSet *projectNameSet = [self.projectNameSet mutableCopy];
        [projectNameSet removeObject:original.name];
        [projectNameSet addObject:updated.name];

        self.projectNameSet = projectNameSet;
    }

    self.projectByUUID[UUID] = updated;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMProjectOriginalProjectUserInfoKey:original, BLMProjectUpdatedProjectUserInfoKey:updated };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectUpdatedNotification object:original userInfo:userInfo];

    if (completion != nil) {
        completion(updated, nil);
    }
}


- (void)deleteProjectForUUID:(NSUUID *)UUID completion:(void(^)(NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMProject *project = self.projectByUUID[UUID];
    assert(project != nil);

    self.projectNameSet = [self.projectNameSet setByRemovingObject:project.name];
    [self.projectByUUID removeObjectForKey:UUID];

    [self archiveCurrentState];

    [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectDeletedNotification object:project userInfo:nil];

    if (completion != nil) {
        completion(nil);
    }
}

#pragma mark BLMBehavior

- (BLMBehavior *)behaviorForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    return self.behaviorByUUID[UUID];
}


- (NSEnumerator<BLMBehavior *> *)behaviorEnumerator {
    assert([NSThread isMainThread]);
    return self.behaviorByUUID.objectEnumerator;
}


- (void)createBehaviorWithName:(NSString *)name continuous:(BOOL)continuous completion:(void(^)(BLMBehavior *behavior, NSError *error))completion {
    assert([NSThread isMainThread]);

    NSUUID *UUID = [NSUUID UUID];
    BLMBehavior *behavior = [[BLMBehavior alloc] initWithUUID:UUID name:name continuous:continuous];

    self.behaviorByUUID[UUID] = behavior;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMBehaviorUpdatedBehaviorUserInfoKey:behavior };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMBehaviorCreatedNotification object:behavior userInfo:userInfo];

    if (completion != nil) {
        completion(behavior, nil);
    }
}


- (void)updateBehaviorForUUID:(NSUUID *)UUID property:(BLMBehaviorProperty)property value:(id)value completion:(void(^)(BLMBehavior *updatedBehavior, NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMBehavior *original = self.behaviorByUUID[UUID];
    BLMBehavior *updated = [original copyWithUpdatedValuesByProperty:@{ @(property):(value ?: [NSNull null]) }];

    if ([BLMUtils isObject:original equalToObject:updated]) {
        if (completion != nil) {
            completion(original, nil);
        }
        return;
    }

    self.behaviorByUUID[UUID] = updated;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMBehaviorOriginalBehaviorUserInfoKey:original, BLMBehaviorUpdatedBehaviorUserInfoKey:updated };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMBehaviorUpdatedNotification object:original userInfo:userInfo];

    if (completion != nil) {
        completion(updated, nil);
    }
}


- (void)deleteBehaviorForUUID:(NSUUID *)UUID completion:(void(^)(NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMBehavior *behavior = self.behaviorByUUID[UUID];
    assert(behavior != nil);

    [self.behaviorByUUID removeObjectForKey:UUID];

    [self archiveCurrentState];

    [[NSNotificationCenter defaultCenter] postNotificationName:BLMBehaviorDeletedNotification object:behavior userInfo:nil];

    if (completion != nil) {
        completion(nil);
    }
}

#pragma mark BLMSession

- (BLMSession *)sessionForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    return self.sessionByUUID[UUID];
}


- (NSEnumerator<BLMSession *> *)sessionEnumerator {
    assert([NSThread isMainThread]);
    return self.sessionByUUID.objectEnumerator;
}


- (void)createSessionWithName:(NSString *)name configurationUUID:(NSUUID *)configurationUUID completion:(nullable void(^)(BLMSession *__nullable session, NSError *__nullable error))completion {
    assert([NSThread isMainThread]);

    NSUUID *UUID = [NSUUID UUID];
    BLMSession *session = [[BLMSession alloc] initWithUUID:UUID name:name configurationUUID:configurationUUID creationDate:[NSDate date] startDate:nil endDate:nil];

    self.sessionByUUID[UUID] = session;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMSessionUpdatedSessionUserInfoKey:session };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMSessionCreatedNotification object:session userInfo:userInfo];

    if (completion != nil) {
        completion(session, nil);
    }
}


- (void)updateSessionForUUID:(NSUUID *)UUID property:(BLMSessionProperty)property value:(nullable id)value completion:(nullable void(^)(BLMSession *__nullable updatedSession, NSError *__nullable error))completion {
    assert([NSThread isMainThread]);

    BLMSession *original = self.sessionByUUID[UUID];
    BLMSession *updated = [original copyWithUpdatedValuesByProperty:@{ @(property):(value ?: [NSNull null]) }];

    if ([BLMUtils isObject:original equalToObject:updated]) {
        if (completion != nil) {
            completion(original, nil);
        }
        return;
    }

    self.sessionByUUID[UUID] = updated;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMSessionOriginalSessionUserInfoKey:original, BLMSessionUpdatedSessionUserInfoKey:updated };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMSessionUpdatedNotification object:original userInfo:userInfo];

    if (completion != nil) {
        completion(updated, nil);
    }
}


- (void)deleteSessionForUUID:(NSUUID *)UUID completion:(nullable void(^)(NSError *__nullable error))completion {
    assert([NSThread isMainThread]);

    BLMSession *session = self.sessionByUUID[UUID];
    assert(session != nil);

    [self.sessionByUUID removeObjectForKey:UUID];

    [self archiveCurrentState];

    [[NSNotificationCenter defaultCenter] postNotificationName:BLMSessionDeletedNotification object:session userInfo:nil];

    if (completion != nil) {
        completion(nil);
    }
}

#pragma mark BLMSessionConfiguration

- (BLMSessionConfiguration *)sessionConfigurationForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    return self.sessionConfigurationByUUID[UUID];
}


- (NSEnumerator<BLMSessionConfiguration *> *)sessionConfigurationEnumerator {
    assert([NSThread isMainThread]);
    return self.sessionConfigurationByUUID.objectEnumerator;
}


- (void)createSessionConfigurationWithCondition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(NSOrderedSet<NSUUID *> *)behaviorUUIDs completion:(void(^)(BLMSessionConfiguration *sessionConfiguration, NSError *error))completion {
    assert([NSThread isMainThread]);

    NSUUID *UUID = [NSUUID UUID];
    BLMSessionConfiguration *sessionConfiguration = [[BLMSessionConfiguration alloc] initWithUUID:UUID condition:condition location:location therapist:therapist observer:observer timeLimit:timeLimit timeLimitOptions:timeLimitOptions behaviorUUIDs:behaviorUUIDs];

    self.sessionConfigurationByUUID[UUID] = sessionConfiguration;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMBehaviorUpdatedBehaviorUserInfoKey:sessionConfiguration };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMSessionConfigurationCreatedNotification object:sessionConfiguration userInfo:userInfo];

    if (completion != nil) {
        completion(sessionConfiguration, nil);
    }
}


- (void)updateSessionConfigurationForUUID:(NSUUID *)UUID property:(BLMSessionConfigurationProperty)property value:(id)value completion:(void(^)(BLMSessionConfiguration *updatedSessionConfiguration, NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMSessionConfiguration *original = self.sessionConfigurationByUUID[UUID];
    BLMSessionConfiguration *updated = [original copyWithUpdatedValuesByProperty:@{ @(property):(value ?: [NSNull null]) }];

    if ([BLMUtils isObject:original equalToObject:updated]) {
        if (completion != nil) {
            completion(original, nil);
        }
        return;
    }

    self.sessionConfigurationByUUID[UUID] = updated;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMSessionConfigurationOriginalSessionConfigurationUserInfoKey:original, BLMSessionConfigurationUpdatedSessionConfigurationUserInfoKey:updated };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMSessionConfigurationUpdatedNotification object:original userInfo:userInfo];

    if (completion != nil) {
        completion(updated, nil);
    }
}


- (void)deleteSessionConfigurationForUUID:(NSUUID *)UUID completion:(void(^)(NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMSessionConfiguration *sessionConfiguration = self.sessionConfigurationByUUID[UUID];
    assert(sessionConfiguration != nil);

    [self.sessionConfigurationByUUID removeObjectForKey:UUID];

    [self archiveCurrentState];

    [[NSNotificationCenter defaultCenter] postNotificationName:BLMSessionConfigurationDeletedNotification object:sessionConfiguration userInfo:nil];

    if (completion != nil) {
        completion(nil);
    }
}

#pragma mark Archiving

- (void)archiveCurrentState {
    assert([NSThread isMainThread]);
    assert(!self.isRestoringArchive);

    if (self.archiveQueue.operationCount > 1) { // No need for enqueued archive operations to happen, since this one is the most up to date
        [self.archiveQueue cancelAllOperations];
    }

    NSDictionary *projectByUUID = [self.projectByUUID copy];
    NSDictionary *behaviorByUUID = [self.behaviorByUUID copy];
    NSDictionary *sessionConfigurationByUUID = [self.sessionConfigurationByUUID copy];

    [self.archiveQueue addOperationWithBlock:^{
        BOOL isDirectory = NO;

        if (![[NSFileManager defaultManager] fileExistsAtPath:ArchiveDirectory() isDirectory:&isDirectory]) {
            if ([[NSFileManager defaultManager] createDirectoryAtPath:ArchiveDirectory() withIntermediateDirectories:YES attributes:nil error:NULL]) {
                isDirectory = YES;
            } else {
                assert(NO);
                return;
            }
        }

        if (!isDirectory) {
            assert(NO);
            return;
        }

        NSString *filePath = [ArchiveDirectory() stringByAppendingPathComponent:ArchiveFileName];

        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]
            && ![[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:@{ NSFileProtectionKey : NSFileProtectionNone }]) {
            assert(NO);
            return;
        }

        NSMutableData *archiveData = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archiveData];

        [archiver encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
        [archiver encodeObject:projectByUUID forKey:@"projectByUUID"];
        [archiver encodeObject:behaviorByUUID forKey:@"behaviorByUUID"];
        [archiver encodeObject:sessionConfigurationByUUID forKey:@"sessionConfigurationByUUID"];
        [archiver finishEncoding];

        NSFileHandle *archiveFile = [NSFileHandle fileHandleForWritingAtPath:filePath];

        [archiveFile truncateFileAtOffset:0];
        [archiveFile writeData:archiveData];
        [archiveFile closeFile];
    }];
}


- (void)restoreArchivedStateWithCompletion:(dispatch_block_t)completion {
    assert([NSThread isMainThread]);
    assert(!self.isRestoringArchive);

    _restoringArchive = YES;

    [self.archiveQueue addOperationWithBlock:^{
        NSMutableDictionary<NSUUID *, BLMProject *> *projectByUUID = nil;
        NSMutableDictionary<NSUUID *, BLMBehavior *> *behaviorByUUID = nil;
        NSMutableDictionary<NSUUID *, BLMSession *> *sessionByUUID = nil;
        NSMutableDictionary<NSUUID *, BLMSessionConfiguration *> *sessionConfigurationByUUID = nil;
        NSString *filePath = [ArchiveDirectory() stringByAppendingPathComponent:ArchiveFileName];
        NSData *archiveData = [NSData dataWithContentsOfFile:filePath];

        if (archiveData.length == 0) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        } else {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archiveData];

            switch ((ArchiveVersion)[unarchiver decodeIntegerForKey:ArchiveVersionKey]) {
                case ArchiveVersionUnknown:
                    assert(NO);
                    break;

                case ArchiveVersionLatest:
                    projectByUUID = [[unarchiver decodeObjectForKey:@"projectByUUID"] mutableCopy];
                    behaviorByUUID = [[unarchiver decodeObjectForKey:@"behaviorByUUID"] mutableCopy];
                    sessionByUUID = [[unarchiver decodeObjectForKey:@"sessionByUUID"] mutableCopy];
                    sessionConfigurationByUUID = [[unarchiver decodeObjectForKey:@"sessionConfigurationByUUID"] mutableCopy];
                    break;
            }

            [unarchiver finishDecoding];
        }

        NSMutableSet<NSUUID *> *referenedBehaviorUUIDs = [NSMutableSet set];
        NSMutableSet<NSUUID *> *referenedSessionUUIDs = [NSMutableSet set];
        NSMutableSet<NSUUID *> *referenedSessionConfigurationUUIDs = [NSMutableSet set];

        [projectByUUID enumerateKeysAndObjectsUsingBlock:^(NSUUID *__nonnull projectUUID, BLMProject *__nonnull project, BOOL *__nonnull stopProjectUUIDEnumeration) {
            [project.sessionUUIDs enumerateObjectsUsingBlock:^(NSUUID *__nonnull sessionUUID, NSUInteger index, BOOL *__nonnull stopSessionUUIDEnumeration) {
                BLMSession *session = sessionByUUID[sessionUUID];
                BLMSessionConfiguration *sessionConfiguration = sessionConfigurationByUUID[session.configurationUUID];

                assert([sessionConfiguration.behaviorUUIDs isSubsetOfSet:[NSSet setWithArray:behaviorByUUID.allKeys]]);

                [referenedBehaviorUUIDs unionSet:sessionConfiguration.behaviorUUIDs.set];
                [referenedSessionConfigurationUUIDs addObject:session.configurationUUID];
            }];

            BLMSessionConfiguration *projectSessionConfiguration = sessionConfigurationByUUID[project.sessionConfigurationUUID];

            NSOrderedSet *sanitizedBehaviorUUIDs = [projectSessionConfiguration.behaviorUUIDs filteredOrderedSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSUUID *behaviorUUID, NSDictionary *bindings) {
                return (behaviorByUUID[behaviorUUID] != nil);
            }]];

            if (![BLMUtils isOrderedSet:sanitizedBehaviorUUIDs equalToOrderedSet:projectSessionConfiguration.behaviorUUIDs]) { // Remove references to behaviors that no longer exist from projects' default session configurations
                projectSessionConfiguration = [projectSessionConfiguration copyWithUpdatedValuesByProperty:@{ @(BLMSessionConfigurationPropertyBehaviorUUIDs):sanitizedBehaviorUUIDs }];
                sessionConfigurationByUUID[project.sessionConfigurationUUID] = projectSessionConfiguration;
            }

            [referenedBehaviorUUIDs unionSet:sanitizedBehaviorUUIDs.set];
            [referenedSessionUUIDs unionSet:project.sessionUUIDs.set];
            [referenedSessionConfigurationUUIDs addObject:project.sessionConfigurationUUID];
        }];

        void (^removeUnreferencedEntries)(NSMutableDictionary *, NSSet *) = ^(NSMutableDictionary<NSUUID *, id> *entryByUUID, NSSet<NSUUID *> *referencedUUIDs) {
            NSMutableArray *unreferencedUUIDs = [NSMutableArray array];

            for (NSUUID *UUID in entryByUUID.keyEnumerator) {
                if (![referencedUUIDs containsObject:UUID]) {
                    [unreferencedUUIDs addObject:UUID];
                }
            }

            [entryByUUID removeObjectsForKeys:unreferencedUUIDs];
        };

        removeUnreferencedEntries(behaviorByUUID, referenedBehaviorUUIDs);
        removeUnreferencedEntries(sessionByUUID, referenedSessionUUIDs);
        removeUnreferencedEntries(sessionConfigurationByUUID, referenedSessionConfigurationUUIDs);

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            assert(self.projectByUUID.count == 0);
            [self.projectByUUID addEntriesFromDictionary:projectByUUID];

            assert(self.behaviorByUUID.count == 0);
            [self.behaviorByUUID addEntriesFromDictionary:behaviorByUUID];

            assert(self.sessionConfigurationByUUID.count == 0);
            [self.sessionConfigurationByUUID addEntriesFromDictionary:sessionConfigurationByUUID];

            assert(self.isRestoringArchive);
            _restoringArchive = NO;
            
            if (completion != nil) {
                completion();
            }
        }];
    }];
}

@end


#pragma mark

@interface AbstractModelObjectEnumerator : NSEnumerator

@property (nonatomic, strong, readonly) NSEnumerator<NSUUID *> *UUIDEnumerator;
@property (nonnull, strong, readonly) BLMDataManager *dataManager;

@end


@implementation AbstractModelObjectEnumerator

- (instancetype)initWithUUIDs:(NSOrderedSet<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager {
    assert(![self isMemberOfClass:[AbstractModelObjectEnumerator class]]);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUIDEnumerator = UUIDs.objectEnumerator;
    _dataManager = dataManager;

    return self;
}


- (id)nextObject {
    id object = nil;

    while (object == nil) {
        NSUUID *UUID = self.UUIDEnumerator.nextObject;

        if (UUID == nil) {
            return nil;
        }

        object = [self objectForUUID:UUID];
    }

    return object;
}


- (NSArray *)allObjects {
    NSMutableArray *allObjects = [NSMutableArray array];

    for (NSUUID *UUID in self.UUIDEnumerator) {
        id object = [self objectForUUID:UUID];

        if (object != nil) {
            [allObjects addObject:object];
        }
    }

    return allObjects;
}


- (id)objectForUUID:(NSUUID *)UUID {
    @throw [NSException exceptionWithName:@"Class Invalid" reason:[NSString stringWithFormat:@"Implementation required for abstract method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)] userInfo:nil];
}

@end


#pragma mark

@implementation NSEnumerator (BLMModelObjectEnumeration)

+ (Class)registerModelObjectEnumeratorSubclassWithName:(const char *)name objectForUUIDBlock:(id(^)(id _self, NSUUID *UUID))objectForUUIDBlock {
    Class concreteSubclass = objc_allocateClassPair([AbstractModelObjectEnumerator class], name, 0);

    if (concreteSubclass == Nil) {
        assert(NO);
        return Nil;
    }

    class_addMethod(concreteSubclass, @selector(objectForUUID:), imp_implementationWithBlock(objectForUUIDBlock), "@@:@");
    objc_registerClassPair(concreteSubclass);

    return concreteSubclass;
}


+ (NSEnumerator<BLMProject *> *)projectEnumeratorForUUIDs:(NSOrderedSet<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager {
    static Class concreteSubclass;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        concreteSubclass = [self registerModelObjectEnumeratorSubclassWithName:"_BLMProjectEnumerator" objectForUUIDBlock:^id(AbstractModelObjectEnumerator *_self, NSUUID *UUID) {
            return [_self.dataManager projectForUUID:UUID];
        }];
    });

    return [(AbstractModelObjectEnumerator *)[concreteSubclass alloc] initWithUUIDs:UUIDs dataManager:dataManager];
}


+ (NSEnumerator<BLMBehavior *> *)behaviorEnumeratorForUUIDs:(NSOrderedSet<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager {
    static Class concreteSubclass;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        concreteSubclass = [self registerModelObjectEnumeratorSubclassWithName:"_BLMBehaviorEnumerator" objectForUUIDBlock:^id(AbstractModelObjectEnumerator *_self, NSUUID *UUID) {
            return [_self.dataManager behaviorForUUID:UUID];
        }];
    });

    return [(AbstractModelObjectEnumerator *)[concreteSubclass alloc] initWithUUIDs:UUIDs dataManager:dataManager];
}


+ (NSEnumerator<BLMSessionConfiguration *> *)sessionConfigurationEnumeratorForUUIDs:(NSOrderedSet<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager {
    static Class concreteSubclass;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        concreteSubclass = [self registerModelObjectEnumeratorSubclassWithName:"_BLMSessionConfigurationEnumerator" objectForUUIDBlock:^id(AbstractModelObjectEnumerator *_self, NSUUID *UUID) {
            return [_self.dataManager sessionConfigurationForUUID:UUID];
        }];
    });

    return [(AbstractModelObjectEnumerator *)[concreteSubclass alloc] initWithUUIDs:UUIDs dataManager:dataManager];
}

@end
