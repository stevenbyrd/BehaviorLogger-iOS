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

    BLMProject *project = [[BLMProject alloc] initWithUUID:[NSUUID UUID] name:name client:client sessionConfigurationUUID:sessionConfigurationUUID sessionByUUID:nil];
    self.projectByUUID[project.UUID] = project;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMProjectNewProjectUserInfoKey:project };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectCreatedNotification object:project userInfo:userInfo];

    if (completion != nil) {
        completion(project, nil);
    }
}


- (void)updateProjectForUUID:(NSUUID *)UUID property:(BLMProjectProperty)property value:(id)value completion:(void(^)(BLMProject *updatedProject, NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMProject *originalProject = self.projectByUUID[UUID];
    BLMProject *updatedProject = [originalProject copyWithUpdatedValuesByProperty:@{ @(property):(value ?: [NSNull null]) }];

    if (![BLMUtils isObject:originalProject equalToObject:updatedProject]) {
        if (property == BLMProjectPropertyName) {
            assert([self.projectNameSet containsObject:originalProject.name]);
            assert(![self.projectNameSet containsObject:updatedProject.name]);

            NSMutableSet *projectNameSet = [self.projectNameSet mutableCopy];
            [projectNameSet removeObject:originalProject.name];
            [projectNameSet addObject:updatedProject.name];

            self.projectNameSet = projectNameSet;
        }

        self.projectByUUID[UUID] = updatedProject;

        [self archiveCurrentState];

        NSDictionary *userInfo = @{ BLMProjectOldProjectUserInfoKey:originalProject, BLMProjectNewProjectUserInfoKey:updatedProject };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectUpdatedNotification object:originalProject userInfo:userInfo];
    }

    if (completion != nil) {
        completion(self.projectByUUID[UUID], nil);
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

    NSDictionary *userInfo = @{ BLMBehaviorNewBehaviorUserInfoKey:behavior };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMBehaviorCreatedNotification object:behavior userInfo:userInfo];

    if (completion != nil) {
        completion(behavior, nil);
    }
}


- (void)updateBehaviorForUUID:(NSUUID *)UUID property:(BLMBehaviorProperty)property value:(id)value completion:(void(^)(BLMBehavior *updatedBehavior, NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMBehavior *original = self.behaviorByUUID[UUID];
    BLMBehavior *updated = [original copyWithUpdatedValuesByProperty:@{ @(property):(value ?: [NSNull null]) }];

    if (![BLMUtils isObject:original equalToObject:updated]) {
        self.behaviorByUUID[UUID] = updated;

        [self archiveCurrentState];

        NSDictionary *userInfo = @{ BLMBehaviorOldBehaviorUserInfoKey:original, BLMBehaviorNewBehaviorUserInfoKey:updated };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLMBehaviorUpdatedNotification object:original userInfo:userInfo];
    }

    if (completion != nil) {
        completion(self.behaviorByUUID[UUID], nil);
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

#pragma mark BLMSessionConfiguration

- (BLMSessionConfiguration *)sessionConfigurationForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    return self.sessionConfigurationByUUID[UUID];
}


- (NSEnumerator<BLMSessionConfiguration *> *)sessionConfigurationEnumerator {
    assert([NSThread isMainThread]);
    return self.sessionConfigurationByUUID.objectEnumerator;
}


- (void)createSessionConfigurationWithCondition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(NSArray<NSUUID *> *)behaviorUUIDs completion:(void(^)(BLMSessionConfiguration *sessionConfiguration, NSError *error))completion {
    assert([NSThread isMainThread]);

    NSUUID *UUID = [NSUUID UUID];
    BLMSessionConfiguration *sessionConfiguration = [[BLMSessionConfiguration alloc] initWithUUID:UUID condition:condition location:location therapist:therapist observer:observer timeLimit:timeLimit timeLimitOptions:timeLimitOptions behaviorUUIDs:behaviorUUIDs];

    self.sessionConfigurationByUUID[UUID] = sessionConfiguration;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMBehaviorNewBehaviorUserInfoKey:sessionConfiguration };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMSessionConfigurationCreatedNotification object:sessionConfiguration userInfo:userInfo];

    if (completion != nil) {
        completion(sessionConfiguration, nil);
    }
}


- (void)updateSessionConfigurationForUUID:(NSUUID *)UUID property:(BLMSessionConfigurationProperty)property value:(id)value completion:(void(^)(BLMSessionConfiguration *updatedSessionConfiguration, NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMSessionConfiguration *original = self.sessionConfigurationByUUID[UUID];
    BLMSessionConfiguration *updated = [original copyWithUpdatedValuesByProperty:@{ @(property):(value ?: [NSNull null]) }];

    if (![BLMUtils isObject:original equalToObject:updated]) {
        self.sessionConfigurationByUUID[UUID] = updated;

        [self archiveCurrentState];

        NSDictionary *userInfo = @{ BLMSessionConfigurationOldSessionConfigurationUserInfoKey:original, BLMSessionConfigurationNewSessionConfigurationUserInfoKey:updated };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLMSessionConfigurationUpdatedNotification object:original userInfo:userInfo];
    }

    if (completion != nil) {
        completion(self.sessionConfigurationByUUID[UUID], nil);
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
                    sessionConfigurationByUUID = [[unarchiver decodeObjectForKey:@"sessionConfigurationByUUID"] mutableCopy];
                    break;
            }

            [unarchiver finishDecoding];
        }

        NSMutableSet<NSUUID *> *referenedBehaviorUUIDs = [NSMutableSet set];

        for (BLMProject *project in projectByUUID.objectEnumerator) {
            BLMSessionConfiguration *sessionConfiguration = sessionConfigurationByUUID[project.sessionConfigurationUUID];

            NSArray *sanitizedBehaviorUUIDs = [sessionConfiguration.behaviorUUIDs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSUUID *UUID, NSDictionary *bindings) {
                return (behaviorByUUID[UUID] != nil);
            }]];

            if (sanitizedBehaviorUUIDs.count != sessionConfiguration.behaviorUUIDs.count) { // Remove references to behaviors that no longer exist from projects' default session configurations
                sessionConfigurationByUUID[project.sessionConfigurationUUID] = [sessionConfiguration copyWithUpdatedValuesByProperty:@{ @(BLMSessionConfigurationPropertyBehaviorUUIDs):sanitizedBehaviorUUIDs }];
            }

            [referenedBehaviorUUIDs addObjectsFromArray:sanitizedBehaviorUUIDs];

            for (BLMSession *session in project.sessionByUUID.objectEnumerator) {
                [referenedBehaviorUUIDs addObjectsFromArray:session.configuration.behaviorUUIDs];
            }
        }

        NSMutableArray *unreferencedBehaviorUUIDs = [NSMutableArray array];

        for (NSUUID *UUID in behaviorByUUID.keyEnumerator) { // Remove behaviors from the data model when there is no longer anything referencing them
            if (![referenedBehaviorUUIDs containsObject:UUID]) {
                [unreferencedBehaviorUUIDs addObject:UUID];
            }
        }

        [behaviorByUUID removeObjectsForKeys:unreferencedBehaviorUUIDs];

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

- (instancetype)initWithArray:(NSArray<NSUUID *> *)array dataManager:(BLMDataManager *)dataManager {
    assert(![self isMemberOfClass:[AbstractModelObjectEnumerator class]]);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUIDEnumerator = array.objectEnumerator;
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


+ (NSEnumerator<BLMProject *> *)projectEnumeratorForUUIDs:(NSArray<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager {
    static Class concreteSubclass;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        concreteSubclass = [self registerModelObjectEnumeratorSubclassWithName:"_BLMProjectEnumerator" objectForUUIDBlock:^id(AbstractModelObjectEnumerator *_self, NSUUID *UUID) {
            return [_self.dataManager projectForUUID:UUID];
        }];
    });

    return [(AbstractModelObjectEnumerator *)[concreteSubclass alloc] initWithArray:UUIDs dataManager:dataManager];
}


+ (NSEnumerator<BLMBehavior *> *)behaviorEnumeratorForUUIDs:(NSArray<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager {
    static Class concreteSubclass;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        concreteSubclass = [self registerModelObjectEnumeratorSubclassWithName:"_BLMBehaviorEnumerator" objectForUUIDBlock:^id(AbstractModelObjectEnumerator *_self, NSUUID *UUID) {
            return [_self.dataManager behaviorForUUID:UUID];
        }];
    });

    return [(AbstractModelObjectEnumerator *)[concreteSubclass alloc] initWithArray:UUIDs dataManager:dataManager];
}


+ (NSEnumerator<BLMSessionConfiguration *> *)sessionConfigurationEnumeratorForUUIDs:(NSArray<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager {
    static Class concreteSubclass;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        concreteSubclass = [self registerModelObjectEnumeratorSubclassWithName:"_BLMSessionConfigurationEnumerator" objectForUUIDBlock:^id(AbstractModelObjectEnumerator *_self, NSUUID *UUID) {
            return [_self.dataManager sessionConfigurationForUUID:UUID];
        }];
    });

    return [(AbstractModelObjectEnumerator *)[concreteSubclass alloc] initWithArray:UUIDs dataManager:dataManager];
}

@end
