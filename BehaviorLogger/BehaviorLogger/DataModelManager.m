//
//  ProjectManager.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "DataModelManager.h"
#import "Project.h"
#import "Schema.h"


NSString *const DataModelArchiveRestoredNotification = @"DataModelArchiveRestoredNotification";

NSString *const DataModelProjectCreatedNotification = @"DataModelProjectCreatedNotification";
NSString *const DataModelProjectDeletedNotification = @"DataModelProjectDeletedNotification";
NSString *const DataModelProjectUpdatedNotification = @"DataModelProjectUpdatedNotification";


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

@interface DataModelManager ()

@property (nonatomic, strong, readonly) NSMutableIndexSet *projectUidSet;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSNumber*, Project *> *projectByUid;
@property (nonatomic, strong, readonly) NSOperationQueue *archiveQueue;

@end


@implementation DataModelManager

+ (void)initializeWithCompletion:(dispatch_block_t)completion {
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        [[DataModelManager sharedManager] restoreArchivedState];
    });
}


+ (instancetype)sharedManager {
    static DataModelManager *sharedManager = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        sharedManager = [[DataModelManager alloc] init];
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


- (Project *)projectForUid:(NSNumber *)uid {
    assert([NSThread isMainThread]);

    Project *project = self.projectByUid[uid];
    assert(project != nil);

    return project;
}

- (void)updateSchemaForProjectUid:(NSNumber *)projectUid toSchema:(Schema *)schema {
    assert([NSThread isMainThread]);

    Project *originalProject = self.projectByUid[projectUid];
    assert(originalProject != nil);

    if ([originalProject.schema isEqual:schema]) {
        assert(NO);
        return;
    }

    self.projectByUid[projectUid] = [[Project alloc] initWithUid:projectUid name:originalProject.name client:originalProject.client schema:schema sessionByUid:originalProject.sessionByUid];

    [[NSNotificationCenter defaultCenter] postNotificationName:DataModelProjectUpdatedNotification object:originalProject];
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


- (void)restoreArchivedState {
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

            [[NSNotificationCenter defaultCenter] postNotificationName:DataModelArchiveRestoredNotification object:self];
        }];
    }];
}

@end
