//
//  BLMProject.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMDataManager.h"
#import "BLMProject.h"
#import "BLMSession.h"
#import "BLMUtils.h"


#pragma mark Constants

NSUInteger const BLMProjectNameMinimumLength = 3;
NSUInteger const BLMProjectClientMinimumLength = 3;

NSString *const BLMProjectCreatedNotification = @"BLMProjectCreatedNotification";
NSString *const BLMProjectDeletedNotification = @"BLMProjectDeletedNotification";
NSString *const BLMProjectUpdatedNotification = @"BLMProjectUpdatedNotification";

NSString *const BLMProjectOriginalProjectUserInfoKey = @"BLMProjectOriginalProjectUserInfoKey";
NSString *const BLMProjectUpdatedProjectUserInfoKey = @"BLMProjectUpdatedProjectUserInfoKey";


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMProject

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name client:(NSString *)client sessionConfigurationUUID:(NSUUID *)sessionConfigurationUUID sessionUUIDs:(nullable NSOrderedSet<NSUUID *> *)sessionUUIDs {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUID = UUID;
    _name = [name copy];
    _client = [client copy];
    _sessionConfigurationUUID = sessionConfigurationUUID;
    _sessionUUIDs = [sessionUUIDs copy];

    return self;
}


- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty {
    return [[BLMProject alloc] initWithUUID:self.UUID
                                       name:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMProjectPropertyName) nullValue:nil defaultValue:self.name]
                                     client:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMProjectPropertyClient) nullValue:nil defaultValue:self.client]
                   sessionConfigurationUUID:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMProjectPropertySessionConfigurationUUID) nullValue:nil defaultValue:self.sessionConfigurationUUID]
                               sessionUUIDs:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMProjectPropertySessionUUIDs) nullValue:nil defaultValue:self.sessionUUIDs]];
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    return [self initWithUUID:[decoder decodeObjectForKey:@"UUID"]
                         name:[decoder decodeObjectForKey:@"name"]
                       client:[decoder decodeObjectForKey:@"client"]
     sessionConfigurationUUID:[decoder decodeObjectForKey:@"sessionConfigurationUUID"]
                 sessionUUIDs:[decoder decodeObjectForKey:@"sessionUUIDs"]];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.UUID forKey:@"UUID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.client forKey:@"client"];
    [coder encodeObject:self.sessionConfigurationUUID forKey:@"sessionConfigurationUUID"];
    [coder encodeObject:self.sessionUUIDs forKey:@"sessionUUIDs"];
    [coder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    return self.UUID.hash;
}


- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMProject *other = (BLMProject *)object;

    return ([BLMUtils isObject:self.UUID equalToObject:other.UUID]
            && [BLMUtils isString:self.name equalToString:other.name]
            && [BLMUtils isString:self.client equalToString:other.client]
            && [BLMUtils isObject:self.sessionConfigurationUUID equalToObject:other.sessionConfigurationUUID]
            && [BLMUtils isOrderedSet:self.sessionUUIDs equalToOrderedSet:other.sessionUUIDs]);
}

@end
