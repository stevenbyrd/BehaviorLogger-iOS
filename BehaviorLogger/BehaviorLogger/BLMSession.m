//
//  BLMSession.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMBehavior.h"
#import "BLMSession.h"
#import "BLMUtils.h"


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMSessionConfiguration

- (instancetype)initWitCondition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(NSArray<NSUUID *> *)behaviorUUIDs {
    assert(behaviorUUIDs != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _condition = [condition copy];
    _location = [location copy];
    _therapist = [therapist copy];
    _observer = [observer copy];
    _timeLimit = timeLimit;
    _timeLimitOptions = timeLimitOptions;
    _behaviorUUIDs = [behaviorUUIDs copy];

    return self;
}


- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty {
    return [[BLMSessionConfiguration alloc] initWitCondition:(valuesByProperty[@(BLMSessionConfigurationPropertyCondition)] ?: self.condition)
                                                    location:(valuesByProperty[@(BLMSessionConfigurationPropertyLocation)] ?: self.location)
                                                   therapist:(valuesByProperty[@(BLMSessionConfigurationPropertyTherapist)] ?: self.therapist)
                                                    observer:(valuesByProperty[@(BLMSessionConfigurationPropertyObserver)] ?: self.observer)
                                                   timeLimit:([valuesByProperty[@(BLMSessionConfigurationPropertyTimeLimit)] integerValue] ?: self.timeLimit)
                                            timeLimitOptions:([valuesByProperty[@(BLMSessionConfigurationPropertyTimeLimitOptions)] integerValue] ?: self.timeLimitOptions)
                                                behaviorUUIDs:(valuesByProperty[@(BLMSessionConfigurationPropertyBehaviorUUIDs)] ?: self.behaviorUUIDs)];
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWitCondition:[aDecoder decodeObjectForKey:@"condition"]
                         location:[aDecoder decodeObjectForKey:@"location"]
                        therapist:[aDecoder decodeObjectForKey:@"therapist"]
                         observer:[aDecoder decodeObjectForKey:@"observer"]
                        timeLimit:[aDecoder decodeIntegerForKey:@"timeLimit"]
                 timeLimitOptions:[aDecoder decodeIntegerForKey:@"timeLimitOptions"]
                    behaviorUUIDs:[aDecoder decodeObjectForKey:@"behaviorUUIDs"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.condition forKey:@"condition"];
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.therapist forKey:@"therapist"];
    [aCoder encodeObject:self.observer forKey:@"observer"];
    [aCoder encodeInteger:self.timeLimit forKey:@"timeLimit"];
    [aCoder encodeInteger:self.timeLimitOptions forKey:@"timeLimitOptions"];
    [aCoder encodeObject:self.behaviorUUIDs forKey:@"behaviorUUIDs"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    assert([NSThread isMainThread]);
    
    return (self.condition.hash
            ^ self.location.hash
            ^ self.therapist.hash
            ^ self.observer.hash
            ^ self.timeLimit
            ^ self.timeLimitOptions
            ^ self.behaviorUUIDs.hash);
}


- (BOOL)isEqual:(id)object {
    assert([NSThread isMainThread]);

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMSessionConfiguration *other = (BLMSessionConfiguration *)object;

    return ([BLMUtils isString:self.condition equalToString:other.condition]
            && [BLMUtils isString:self.location equalToString:other.location]
            && [BLMUtils isString:self.therapist equalToString:other.therapist]
            && [BLMUtils isString:self.observer equalToString:other.observer]
            && [BLMUtils isArray:self.behaviorUUIDs equalToArray:other.behaviorUUIDs]
            && (self.timeLimit == other.timeLimit)
            && (self.timeLimitOptions == other.timeLimitOptions));
}

@end


#pragma mark

@implementation BLMSession

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name configuration:(BLMSessionConfiguration *)configuration {
    assert(UUID != nil);
    assert(name.length > 0);
    assert(configuration != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUID = UUID;
    _name = [name copy];
    _configuration = configuration;

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUUID:[aDecoder decodeObjectForKey:@"UUID"]
                        name:[aDecoder decodeObjectForKey:@"name"]
               configuration:[aDecoder decodeObjectForKey:@"configuration"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.UUID forKey:@"UUID"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.configuration forKey:@"configuration"];
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

    BLMSession *other = (BLMSession *)object;

    return ([BLMUtils isObject:self.UUID equalToObject:other.UUID]
            && [BLMUtils isString:self.name equalToString:other.name]
            && [BLMUtils isObject:self.configuration equalToObject:other.configuration]);
}

@end
