//
//  BLMProject.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMProject.h"
#import "BLMSession.h"
#import "BLMUtils.h"


NSUInteger const BLMProjectNameMinimumLength = 3;
NSUInteger const BLMProjectClientMinimumLength = 3;

NSString *const BLMProjectCreatedNotification = @"BLMProjectCreatedNotification";
NSString *const BLMProjectDeletedNotification = @"BLMProjectDeletedNotification";
NSString *const BLMProjectUpdatedNotification = @"BLMProjectUpdatedNotification";

NSString *const BLMProjectOldProjectUserInfoKey = @"BLMProjectOldProjectUserInfoKey";
NSString *const BLMProjectNewProjectUserInfoKey = @"BLMProjectNewProjectUserInfoKey";


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMProject

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name client:(NSString *)client defaultSessionConfiguration:(BLMSessionConfiguration *)defaultSessionConfiguration sessionByUUID:(NSDictionary<NSUUID *, BLMSession *> *)sessionByUUID {
    assert(UUID != nil);
    assert(name.length > BLMProjectNameMinimumLength);
    assert(client.length > BLMProjectClientMinimumLength);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUID = UUID;
    _name = [name copy];
    _client = [client copy];
    _defaultSessionConfiguration = (defaultSessionConfiguration ?: [[BLMSessionConfiguration alloc] initWitCondition:nil location:nil therapist:nil observer:nil timeLimit:-1 timeLimitOptions:0 behaviorUUIDs:@[]]);
    _sessionByUUID = [sessionByUUID copy];

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUUID:[aDecoder decodeObjectForKey:@"UUID"]
                         name:[aDecoder decodeObjectForKey:@"name"]
                       client:[aDecoder decodeObjectForKey:@"client"]
  defaultSessionConfiguration:[aDecoder decodeObjectForKey:@"defaultSessionConfiguration"]
                sessionByUUID:[aDecoder decodeObjectForKey:@"sessionByUUID"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.UUID forKey:@"UUID"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.client forKey:@"client"];
    [aCoder encodeObject:self.defaultSessionConfiguration forKey:@"defaultSessionConfiguration"];
    [aCoder encodeObject:self.sessionByUUID forKey:@"sessionByUUID"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    assert([NSThread isMainThread]);

    return self.UUID.hash;
}


- (BOOL)isEqual:(id)object {
    assert([NSThread isMainThread]);

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMProject *other = (BLMProject *)object;

    return ([BLMUtils isObject:self.UUID equalToObject:other.UUID]
            && [BLMUtils isString:self.name equalToString:other.name]
            && [BLMUtils isString:self.client equalToString:other.client]
            && [BLMUtils isObject:self.defaultSessionConfiguration equalToObject:other.defaultSessionConfiguration]
            && [self.sessionByUUID isEqualToDictionary:other.sessionByUUID]);
}

@end
