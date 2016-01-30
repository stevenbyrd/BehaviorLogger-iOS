//
//  BLMDataManager.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMSchema.h"
#import "BLMUtils.h"


NSString *const BLMDataManagerArchiveRestoredNotification = @"BLMDataManagerArchiveRestoredNotification";

NSString *const BLMProjectCreatedNotification = @"BLMProjectCreatedNotification";
NSString *const BLMProjectDeletedNotification = @"BLMProjectDeletedNotification";
NSString *const BLMProjectUpdatedNotification = @"BLMProjectUpdatedNotification";

NSString *const BLMProjectOldProjectUserInfoKey = @"BLMProjectOldProjectUserInfoKey";
NSString *const BLMProjectNewProjectUserInfoKey = @"BLMProjectNewProjectUserInfoKey";

NSString *const BLMDataManagerProjectErrorDomain = @"com.3bird.BehaviorLogger.Project";


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

@property (nonatomic, strong, readonly) NSMutableIndexSet *projectUidSet;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSNumber*, BLMProject *> *projectByUid;
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

    _projectUidSet = [NSMutableIndexSet indexSet];

    _projectByUid = [NSMutableDictionary dictionary];

    _archiveQueue = [[NSOperationQueue alloc] init];
    _archiveQueue.name = [NSString stringWithFormat:@"%@ - Archive Queue", NSStringFromClass([self class])];
    _archiveQueue.qualityOfService = NSOperationQualityOfServiceBackground;
    _archiveQueue.maxConcurrentOperationCount = 1;

    return self;
}

#pragma mark Internal State

- (NSIndexSet *)allProjectUids {
    assert([NSThread isMainThread]);

    return self.projectUidSet.copy;
}


- (BLMProject *)projectForUid:(NSNumber *)uid {
    assert([NSThread isMainThread]);

    BLMProject *project = self.projectByUid[uid];
    assert(project != nil);

    return project;
}


- (void)createProjectWithName:(NSString *)name client:(NSString *)client completion:(void(^)(BLMProject *createdProject, NSError *error))completion {
    assert([NSThread isMainThread]);
    NSParameterAssert(name.length >= BLMProjectNameMinimumLength);
    NSParameterAssert(client.length >= BLMProjectClientMinimumLength);
    NSParameterAssert(completion != nil);

    __block BLMProject *project = nil;
    __block NSError *error = nil;

    NSString *lowerCaseName = [name.lowercaseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [self.projectUidSet enumerateIndexesUsingBlock:^(NSUInteger uid, BOOL * _Nonnull stop) {
        if ([BLMUtils isString:self.projectByUid[@(uid)].name.lowercaseString equalToString:lowerCaseName]) {
            error = [NSError errorWithDomain:BLMDataManagerProjectErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"A project with that name already exists." }];
            *stop = YES;
            return;
        }
    }];

    if (error == nil) {
        NSUInteger lastUid = ((self.projectUidSet.count > 0) ? self.projectUidSet.lastIndex : 0);
        NSNumber *uid = @(lastUid + 1);

        [self.projectUidSet addIndex:uid.integerValue];

        project = [[BLMProject alloc] initWithUid:uid name:name client:client defaultSessionConfiguration:nil sessionByUid:nil];
        self.projectByUid[uid] = project;

        [self archiveCurrentState];

        NSDictionary *userInfo = @{ BLMProjectNewProjectUserInfoKey:project };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectCreatedNotification object:project userInfo:userInfo];
    }

    completion(project, error);
}

- (void)updateDefaultSessionConfigurationForProjectUid:(NSNumber *)projectUid configuration:(BLMSessionConfiguration *)configuration {
    assert([NSThread isMainThread]);

    BLMProject *project = self.projectByUid[projectUid];
    assert(project != nil);

    if (![BLMUtils isObject:project.defaultSessionConfiguration equalToObject:configuration]) {
        BLMProject *updatedProject = [[BLMProject alloc] initWithUid:projectUid name:project.name client:project.client defaultSessionConfiguration:configuration sessionByUid:project.sessionByUid];
        self.projectByUid[projectUid] = updatedProject;

        NSDictionary *userInfo = @{ BLMProjectOldProjectUserInfoKey:project, BLMProjectNewProjectUserInfoKey:updatedProject };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLMProjectUpdatedNotification object:project userInfo:userInfo];
    }
}

#pragma mark Archiving

- (void)archiveCurrentState {
    assert([NSThread isMainThread]);
    assert(!self.isRestoringArchive);

    if (self.archiveQueue.operationCount > 1) { // No need for enqueued archive operations to happen, since this one is the most up to date
        [self.archiveQueue cancelAllOperations];
    }

    NSIndexSet *projectUidSet = self.projectUidSet.copy;
    NSDictionary *projectByUid = self.projectByUid.copy;

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

        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath] && ![[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:@{ NSFileProtectionKey : NSFileProtectionNone }]) {
            assert(NO);
            return;
        }

        NSMutableData *archiveData = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archiveData];

        [archiver encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
        [archiver encodeObject:projectUidSet forKey:@"projectUidSet"];
        [archiver encodeObject:projectByUid forKey:@"projectByUid"];
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
        NSIndexSet *projectUidSet = [NSIndexSet indexSet];
        NSDictionary *projectByUid = @{};
        NSString *filePath = [ArchiveDirectory() stringByAppendingPathComponent:ArchiveFileName];
        NSData *archiveData = [NSData dataWithContentsOfFile:filePath];

        if (archiveData.length > 0) {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archiveData];
            ArchiveVersion version = [unarchiver decodeIntegerForKey:ArchiveVersionKey];

            switch (version) {
                case ArchiveVersionUnknown:
                    assert(NO);
                    break;

                case ArchiveVersionLatest:
                    projectUidSet = [unarchiver decodeObjectForKey:@"projectUidSet"];
                    projectByUid = [unarchiver decodeObjectForKey:@"projectByUid"];
                    break;
            }

            [unarchiver finishDecoding];
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            assert(self.projectUidSet.count == 0);
            [self.projectUidSet addIndexes:projectUidSet];

            assert(self.projectByUid.count == 0);
            [self.projectByUid addEntriesFromDictionary:projectByUid];

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
