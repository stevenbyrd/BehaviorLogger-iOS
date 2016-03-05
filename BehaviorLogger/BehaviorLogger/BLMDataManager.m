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

@interface BLMDataManager ()

@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMProject *> *projectByUUID;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSUUID*, BLMBehavior *> *behaviorByUUID;
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

    _archiveQueue = [[NSOperationQueue alloc] init];
    _archiveQueue.name = [NSString stringWithFormat:@"%@ - Archive Queue", NSStringFromClass([self class])];
    _archiveQueue.qualityOfService = NSOperationQualityOfServiceBackground;
    _archiveQueue.maxConcurrentOperationCount = 1;

    return self;
}

#pragma mark Project State

- (NSEnumerator<NSUUID *> *)projectUUIDEnumerator {
    assert([NSThread isMainThread]);

    return self.projectByUUID.keyEnumerator;
}


- (BLMProject *)projectForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    assert(UUID != nil);

    return self.projectByUUID[UUID];
}


- (void)createProjectWithName:(NSString *)name client:(NSString *)client completion:(void(^)(BLMProject *project, NSError *error))completion {
    assert([NSThread isMainThread]);
    assert(name.length >= BLMProjectNameMinimumLength);
    assert(client.length >= BLMProjectClientMinimumLength);
    assert(completion != nil);

    NSString *lowercaseName = [name.lowercaseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    for (NSUUID *UUID in self.projectByUUID.keyEnumerator) {
        if ([BLMUtils isString:self.projectByUUID[UUID].name.lowercaseString equalToString:lowercaseName]) {
            completion(nil, [NSError errorWithDomain:BLMDataManagerProjectErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"A project with that name already exists." }]);
            return;
        }
    }

    NSUUID *UUID = [NSUUID UUID];
    BLMProject *project = [[BLMProject alloc] initWithUUID:UUID name:name client:client defaultSessionConfiguration:nil sessionByUUID:nil];

    self.projectByUUID[UUID] = project;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMProjectNewProjectUserInfoKey:project };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectCreatedNotification object:project userInfo:userInfo];

    completion(project, nil);
}


- (void)updateProjectForUUID:(NSUUID *)UUID property:(BLMProjectProperty)property value:(id)value completion:(void(^)(BLMProject *updatedProject, NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMProject *originalProject = self.projectByUUID[UUID];
    assert(originalProject != nil);

    BLMProject *updatedProject;

    switch (property) {
        case BLMProjectPropertyName: {
            updatedProject = [[BLMProject alloc] initWithUUID:UUID name:value client:originalProject.client defaultSessionConfiguration:originalProject.defaultSessionConfiguration sessionByUUID:originalProject.sessionByUUID];
            break;
        }

        case BLMProjectPropertyClient: {
            updatedProject = [[BLMProject alloc] initWithUUID:UUID name:originalProject.name client:value defaultSessionConfiguration:originalProject.defaultSessionConfiguration sessionByUUID:originalProject.sessionByUUID];
            break;
        }

        case BLMProjectPropertyDefaultSessionConfiguration: {
            updatedProject = [[BLMProject alloc] initWithUUID:UUID name:originalProject.name client:originalProject.client defaultSessionConfiguration:value sessionByUUID:originalProject.sessionByUUID];
            break;
        }
    }

    if (![BLMUtils isObject:originalProject equalToObject:updatedProject]) {
        assert(updatedProject != nil);
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

- (NSEnumerator<NSUUID *> *)behaviorUUIDEnumerator {
    assert([NSThread isMainThread]);

    return self.behaviorByUUID.keyEnumerator;

}


- (BLMBehavior *)behaviorForUUID:(NSUUID *)UUID {
    assert([NSThread isMainThread]);
    assert(UUID != nil);

    return self.behaviorByUUID[UUID];
}


- (void)createBehaviorWithName:(NSString *)name continuous:(BOOL)continuous completion:(void(^)(BLMBehavior *behavior, NSError *error))completion {
    assert([NSThread isMainThread]);
    assert(completion != nil);

    NSUUID *UUID = [NSUUID UUID];
    BLMBehavior *behavior = [[BLMBehavior alloc] initWithUUID:UUID name:name continuous:continuous];

    self.behaviorByUUID[UUID] = behavior;

    [self archiveCurrentState];

    NSDictionary *userInfo = @{ BLMBehaviorNewBehaviorUserInfoKey:behavior };
    [[NSNotificationCenter defaultCenter] postNotificationName:BLMBehaviorCreatedNotification object:behavior userInfo:userInfo];

    completion(behavior, nil);
}


- (void)updateBehaviorForUUID:(NSUUID *)UUID property:(BLMBehaviorProperty)property value:(id)value completion:(void(^)(BLMBehavior *updatedBehavior, NSError *error))completion {
    assert([NSThread isMainThread]);

    BLMBehavior *originalBehavior = self.behaviorByUUID[UUID];
    assert(originalBehavior != nil);

    BLMBehavior *updatedBehavior;

    switch (property) {
        case BLMBehaviorPropertyName: {
            updatedBehavior = [[BLMBehavior alloc] initWithUUID:UUID name:value continuous:originalBehavior.isContinuous];
            break;
        }

        case BLMBehaviorPropertyContinuous: {
            updatedBehavior = [[BLMBehavior alloc] initWithUUID:UUID name:originalBehavior.name continuous:[(NSNumber *)value boolValue]];
            break;
        }
    }

    if (![BLMUtils isObject:originalBehavior equalToObject:updatedBehavior]) {
        assert(updatedBehavior != nil);
        self.behaviorByUUID[UUID] = updatedBehavior;

        [self archiveCurrentState];

        NSDictionary *userInfo = @{ BLMBehaviorOldBehaviorUserInfoKey:originalBehavior, BLMBehaviorNewBehaviorUserInfoKey:updatedBehavior };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLMBehaviorUpdatedNotification object:originalBehavior userInfo:userInfo];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:BLMBehaviorDeletedNotification object:behavior userInfo:nil];

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
        NSDictionary<NSUUID *, BLMProject *> *projectByUUID = nil;
        NSDictionary<NSUUID *, BLMBehavior *> *behaviorByUUID = nil;
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
                    projectByUUID = [unarchiver decodeObjectForKey:@"projectByUUID"];
                    behaviorByUUID = [unarchiver decodeObjectForKey:@"behaviorByUUID"];
                    break;
            }

            [unarchiver finishDecoding];
        }

        NSMutableSet<NSUUID *> *referenedBehaviorUUIDs = [NSMutableSet set];

        for (BLMProject *project in projectByUUID.objectEnumerator) {
            [referenedBehaviorUUIDs addObjectsFromArray:project.defaultSessionConfiguration.behaviorUUIDs];

            for (BLMSession *session in project.sessionByUUID.objectEnumerator) {
                [referenedBehaviorUUIDs addObjectsFromArray:session.configuration.behaviorUUIDs];
            }
        }

        if (referenedBehaviorUUIDs.count > behaviorByUUID.count) {
            NSMutableDictionary<NSUUID *, BLMBehavior *> *sanitizedBehaviorByUUID = [behaviorByUUID mutableCopy];

            for (NSUUID *UUID in behaviorByUUID.keyEnumerator) {
                if (![referenedBehaviorUUIDs containsObject:UUID]) {
                    [sanitizedBehaviorByUUID removeObjectForKey:UUID];
                }
            }

            behaviorByUUID = sanitizedBehaviorByUUID;
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            assert(self.projectByUUID.count == 0);
            [self.projectByUUID addEntriesFromDictionary:projectByUUID];

            assert(self.behaviorByUUID.count == 0);
            [self.behaviorByUUID addEntriesFromDictionary:behaviorByUUID];

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
