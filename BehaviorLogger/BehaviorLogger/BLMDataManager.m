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


NSString *const BLMDataManagerArchiveRestoredNotification = @"BLMDataManagerArchiveRestoredNotification";

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

@interface BLMModelObjectEnumerator<ObjectType> ()

@property (nonatomic, strong, readonly) NSEnumerator<NSUUID *> *UUIDEnumerator;
@property (nonatomic, copy, readonly) ObjectType (^objectRetrievalBlock)(NSUUID *UUID);

- (instancetype)initWithUUIDEnumerator:(NSEnumerator<NSUUID *> *)UUIDEnumerator objectRetrievalBlock:(ObjectType(^)(NSUUID *UUID))objectRetrievalBlock;

@end


@implementation BLMModelObjectEnumerator

- (instancetype)initWithUUIDEnumerator:(NSEnumerator<NSUUID *> *)UUIDEnumerator objectRetrievalBlock:(id(^)(NSUUID *UUID))objectRetrievalBlock {
    assert(![self isMemberOfClass:[BLMModelObjectEnumerator class]]);
    assert([self conformsToProtocol:@protocol(BLMUUIDEnumeration)]);
    assert(UUIDEnumerator != nil);
    assert(objectRetrievalBlock != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUIDEnumerator = UUIDEnumerator;
    _objectRetrievalBlock = [objectRetrievalBlock copy];

    return self;
}


- (id)nextObject {
    id object = nil;

    while (object == nil) {
        NSUUID *UUID = self.UUIDEnumerator.nextObject;

        if (UUID == nil) {
            return nil;
        }

        object = self.objectRetrievalBlock(UUID);
    }

    return object;
}


- (NSArray *)allObjects {
    NSMutableArray *allObjects = [NSMutableArray array];

    for (NSUUID *UUID in self.UUIDEnumerator.allObjects) {
        id object = self.objectRetrievalBlock(UUID);

        if (object != nil) {
            [allObjects addObject:object];
        }
    }

    return allObjects;
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])objects count:(NSUInteger)count {
    typedef NS_ENUM(NSUInteger, EnumerationState) {
        EnumerationStateUninitialized,
        EnumerationStateStarted,
    };

    switch ((EnumerationState)state->state) {
        case EnumerationStateUninitialized:
            state->state = EnumerationStateStarted;
            state->mutationsPtr = &state->state; // We're ignoring mutations, so mutationsPtr points to value that will not change (note: must not be NULL)

        case EnumerationStateStarted: {
            assert(count >= 1);
            objects[0] = nil;

            while (objects[0] == nil) {
                NSUUID *UUID = self.UUIDEnumerator.nextObject;

                if (UUID == nil) {
                    return 0;
                }

                objects[0] = self.objectRetrievalBlock(UUID);
            }

            state->itemsPtr = objects;
            
            return 1;
        }
    }
}

@end


#pragma mark

@implementation BLMBehaviorEnumerator

+ (instancetype)enumeratorFromUUIDEnumerator:(NSEnumerator<NSUUID *> *)UUIDEnumerator {
    return [[self alloc] initWithUUIDEnumerator:UUIDEnumerator objectRetrievalBlock:^BLMBehavior *(NSUUID *UUID) {
        return [[BLMDataManager sharedManager] behaviorForUUID:UUID];
    }];
}

@end


#pragma mark

@implementation BLMProjectEnumerator

+ (instancetype)enumeratorFromUUIDEnumerator:(NSEnumerator<NSUUID *> *)UUIDEnumerator {
    return [[self alloc] initWithUUIDEnumerator:UUIDEnumerator objectRetrievalBlock:^BLMProject *(NSUUID *UUID) {
        return [[BLMDataManager sharedManager] projectForUUID:UUID];
    }];
}

@end


#pragma mark

@implementation BLMSessionConfigurationEnumerator

+ (instancetype)enumeratorFromUUIDEnumerator:(NSEnumerator<NSUUID *> *)UUIDEnumerator {
    return [[self alloc] initWithUUIDEnumerator:UUIDEnumerator objectRetrievalBlock:^BLMSessionConfiguration *(NSUUID *UUID) {
        return [[BLMDataManager sharedManager] sessionConfigurationForUUID:UUID];
    }];
}

@end


#pragma mark

@interface BLMDataManager ()

@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMProject *> *projectByUUID;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMBehavior *> *behaviorByUUID;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMSessionConfiguration *> *sessionConfigurationByUUID;
@property (nonatomic, strong, readonly) NSOperationQueue *archiveQueue;

@end


@implementation BLMDataManager

#pragma Lifecycle

+ (void)initializeWithCompletion:(dispatch_block_t)completion {
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        [[BLMDataManager sharedManager] restoreArchivedStateWithCompletion:completion];
    });
}


+ (instancetype)sharedManager {
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

#pragma mark Project State

- (BLMProject *)projectForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    assert(UUID != nil);

    return self.projectByUUID[UUID];
}


- (BLMProjectEnumerator *)projectEnumerator {
    assert([NSThread isMainThread]);

    return [BLMProjectEnumerator enumeratorFromUUIDEnumerator:self.projectByUUID.keyEnumerator];
}


- (void)createProjectWithName:(NSString *)name client:(NSString *)client sessionConfigurationUUID:(NSUUID *)sessionConfigurationUUID completion:(void(^)(BLMProject *project, NSError *error))completion {
    assert([NSThread isMainThread]);

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

    [self.projectByUUID removeObjectForKey:UUID];

    [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectDeletedNotification object:project userInfo:nil];

    if (completion != nil) {
        completion(nil);
    }
}

#pragma mark Behavior State

- (BLMBehavior *)behaviorForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    assert(UUID != nil);

    return self.behaviorByUUID[UUID];
}


- (BLMBehaviorEnumerator *)behaviorEnumerator {
    assert([NSThread isMainThread]);

    return [BLMBehaviorEnumerator enumeratorFromUUIDEnumerator:self.behaviorByUUID.keyEnumerator];
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

#pragma mark Session Configuration State

- (BLMSessionConfiguration *)sessionConfigurationForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);

    return self.sessionConfigurationByUUID[UUID];
}


- (BLMSessionConfigurationEnumerator *)sessionConfigurationEnumerator {
    assert([NSThread isMainThread]);

    return [BLMSessionConfigurationEnumerator enumeratorFromUUIDEnumerator:self.sessionConfigurationByUUID.keyEnumerator];
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
            
            [[NSNotificationCenter defaultCenter] postNotificationName:BLMDataManagerArchiveRestoredNotification object:self];
            
            if (completion != nil) {
                completion();
            }
        }];
    }];
}

@end
