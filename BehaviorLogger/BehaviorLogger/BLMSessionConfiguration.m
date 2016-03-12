//
//  BLMSessionConfiguration.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/9/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMDataManager.h"
#import "BLMSessionConfiguration.h"
#import "BLMUtils.h"


NSString *const BLMSessionConfigurationCreatedNotification = @"BLMSessionConfigurationCreatedNotification";
NSString *const BLMSessionConfigurationDeletedNotification = @"BLMSessionConfigurationDeletedNotification";
NSString *const BLMSessionConfigurationUpdatedNotification = @"BLMSessionConfigurationUpdatedNotification";

NSString *const BLMSessionConfigurationOldSessionConfigurationUserInfoKey = @"BLMSessionConfigurationOldSessionConfigurationUserInfoKey";
NSString *const BLMSessionConfigurationNewSessionConfigurationUserInfoKey = @"BLMSessionConfigurationNewSessionConfigurationUserInfoKey";


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMSessionConfiguration

- (instancetype)initWithUUID:(NSUUID *)UUID condition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(NSArray<NSUUID *> *)behaviorUUIDs {
    assert(UUID != nil);
    assert(behaviorUUIDs != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUID = UUID;
    _condition = [condition copy];
    _location = [location copy];
    _therapist = [therapist copy];
    _observer = [observer copy];
    _timeLimit = timeLimit;
    _timeLimitOptions = timeLimitOptions;
    _behaviorUUIDs = [behaviorUUIDs copy];

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    return [self initWithUUID:[decoder decodeObjectForKey:@"UUID"]
                    condition:[decoder decodeObjectForKey:@"condition"]
                     location:[decoder decodeObjectForKey:@"location"]
                    therapist:[decoder decodeObjectForKey:@"therapist"]
                     observer:[decoder decodeObjectForKey:@"observer"]
                    timeLimit:[decoder decodeIntegerForKey:@"timeLimit"]
             timeLimitOptions:[decoder decodeIntegerForKey:@"timeLimitOptions"]
                behaviorUUIDs:[decoder decodeObjectForKey:@"behaviorUUIDs"]];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.UUID forKey:@"UUID"];
    [coder encodeObject:self.condition forKey:@"condition"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.therapist forKey:@"therapist"];
    [coder encodeObject:self.observer forKey:@"observer"];
    [coder encodeInteger:self.timeLimit forKey:@"timeLimit"];
    [coder encodeInteger:self.timeLimitOptions forKey:@"timeLimitOptions"];
    [coder encodeObject:self.behaviorUUIDs forKey:@"behaviorUUIDs"];
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

    BLMSessionConfiguration *other = (BLMSessionConfiguration *)object;

    return ([BLMUtils isObject:self.UUID equalToObject:other.UUID]
            && [BLMUtils isString:self.condition equalToString:other.condition]
            && [BLMUtils isString:self.location equalToString:other.location]
            && [BLMUtils isString:self.therapist equalToString:other.therapist]
            && [BLMUtils isString:self.observer equalToString:other.observer]
            && [BLMUtils isArray:self.behaviorUUIDs equalToArray:other.behaviorUUIDs]
            && (self.timeLimit == other.timeLimit)
            && (self.timeLimitOptions == other.timeLimitOptions));
}


- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty {
    return [[BLMSessionConfiguration alloc] initWithUUID:self.UUID
                                               condition:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionConfigurationPropertyCondition) nullValue:nil defaultValue:self.condition]
                                                location:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionConfigurationPropertyLocation) nullValue:nil defaultValue:self.location]
                                               therapist:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionConfigurationPropertyTherapist) nullValue:nil defaultValue:self.therapist]
                                                observer:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionConfigurationPropertyObserver) nullValue:nil defaultValue:self.observer]
                                               timeLimit:[BLMUtils integerFromDictionary:valuesByProperty forKey:@(BLMSessionConfigurationPropertyTimeLimit) defaultValue:self.timeLimit]
                                        timeLimitOptions:[BLMUtils integerFromDictionary:valuesByProperty forKey:@(BLMSessionConfigurationPropertyTimeLimitOptions) defaultValue:self.timeLimitOptions]
                                           behaviorUUIDs:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMSessionConfigurationPropertyBehaviorUUIDs) nullValue:nil defaultValue:self.behaviorUUIDs]];
}


- (NSEnumerator<BLMBehavior *> *)behaviorEnumerator {
    return [BLMBehaviorEnumerator enumeratorFromUUIDEnumerator:self.behaviorUUIDs.objectEnumerator];
}

@end
