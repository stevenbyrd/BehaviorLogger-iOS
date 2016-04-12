//
//  BLMSession.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMBehavior.h"
#import "BLMDataManager.h"
#import "BLMSession.h"
#import "BLMSessionConfiguration.h"
#import "BLMUtils.h"


#pragma mark Constants

NSString *const BLMSessionCreatedNotification = @"BLMSessionCreatedNotification";
NSString *const BLMSessionDeletedNotification = @"BLMSessionDeletedNotification";
NSString *const BLMSessionUpdatedNotification = @"BLMSessionUpdatedNotification";

NSString *const BLMSessionOriginalSessionUserInfoKey = @"BLMSessionOriginalSessionUserInfoKey";
NSString *const BLMSessionUpdatedSessionUserInfoKey = @"BLMSessionUpdatedSessionUserInfoKey";


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMSession

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name sessionConfigurationUUID:(NSUUID *)sessionConfigurationUUID {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUID = UUID;
    _name = [name copy];
    _sessionConfigurationUUID = sessionConfigurationUUID;

    return self;
}


- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty {
    return [[BLMSession alloc] initWithUUID:self.UUID
                                       name:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionPropertyName) nullValue:nil defaultValue:self.name]
                   sessionConfigurationUUID:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionPropertySessionConfigurationUUID) nullValue:nil defaultValue:self.sessionConfigurationUUID]];
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    return [self initWithUUID:[decoder decodeObjectForKey:@"UUID"]
                         name:[decoder decodeObjectForKey:@"name"]
                sessionConfigurationUUID:[decoder decodeObjectForKey:@"sessionConfigurationUUID"]];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.UUID forKey:@"UUID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.sessionConfigurationUUID forKey:@"sessionConfigurationUUID"];
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

    BLMSession *other = (BLMSession *)object;

    return ([BLMUtils isObject:self.UUID equalToObject:other.UUID]
            && [BLMUtils isString:self.name equalToString:other.name]
            && [BLMUtils isObject:self.sessionConfigurationUUID equalToObject:other.sessionConfigurationUUID]);
}

@end
