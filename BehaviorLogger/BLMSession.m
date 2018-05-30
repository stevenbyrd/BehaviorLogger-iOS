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


NS_ASSUME_NONNULL_BEGIN


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

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name configurationUUID:(NSUUID *)configurationUUID creationDate:(NSDate *)creationDate startDate:(nullable NSDate *)startDate endDate:(nullable NSDate *)endDate {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUID = UUID;
    _name = [name copy];
    _configurationUUID = configurationUUID;
    _creationDate = creationDate;
    _startDate = startDate;
    _endDate = endDate;

    return self;
}


- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty {
    return [[BLMSession alloc] initWithUUID:self.UUID
                                       name:self.name
                          configurationUUID:self.configurationUUID
                               creationDate:self.creationDate
                                  startDate:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionPropertyStartDate) nullValue:nil defaultValue:self.startDate]
                                    endDate:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionPropertyEndDate) nullValue:nil defaultValue:self.endDate]];
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    return [self initWithUUID:[decoder decodeObjectForKey:@"UUID"]
                         name:[decoder decodeObjectForKey:@"name"]
            configurationUUID:[decoder decodeObjectForKey:@"configurationUUID"]
                 creationDate:[decoder decodeObjectForKey:@"creationDate"]
                    startDate:[decoder decodeObjectForKey:@"startDate"]
                      endDate:[decoder decodeObjectForKey:@"endDate"]];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.UUID forKey:@"UUID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.configurationUUID forKey:@"configurationUUID"];
    [coder encodeObject:self.creationDate forKey:@"creationDate"];
    [coder encodeObject:self.startDate forKey:@"startDate"];
    [coder encodeObject:self.endDate forKey:@"endDate"];
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
            && [BLMUtils isObject:self.configurationUUID equalToObject:other.configurationUUID]);
}

@end


NS_ASSUME_NONNULL_END