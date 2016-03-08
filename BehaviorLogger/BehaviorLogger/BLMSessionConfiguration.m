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

@interface BehaviorEnumerator : NSEnumerator<BLMBehavior *>

@property (nonatomic, strong, readonly) NSEnumerator<NSUUID *> *UUIDEnumerator;
@property (nonatomic, copy, readonly) NSArray<NSUUID *> *behaviorUUIDs;

@end


@implementation BehaviorEnumerator

- (instancetype)initWithBehaviorUUIDs:(NSArray<NSUUID *> *)behaviorUUIDs {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    _behaviorUUIDs = [behaviorUUIDs copy];

    return self;
}


- (id)nextObject {
    if (self.UUIDEnumerator == nil) {
        _UUIDEnumerator = self.behaviorUUIDs.objectEnumerator;
    }

    NSUUID *UUID = self.UUIDEnumerator.nextObject;

    return ((UUID == nil) ? nil : [[BLMDataManager sharedManager] behaviorForUUID:UUID]);
}


- (NSArray *)allObjects {
    NSMutableArray *allObjects = [NSMutableArray array];

    for (NSUUID *UUID in self.behaviorUUIDs) {
        BLMBehavior *behavior = [[BLMDataManager sharedManager] behaviorForUUID:UUID];

        if (behavior != nil) {
            [allObjects addObject:behavior];
        }
    }

    return allObjects;
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])objects count:(NSUInteger)count {
    typedef NS_ENUM(NSUInteger, EnumerationState) {
        EnumerationStateUninitialized,
        EnumerationStateStarted,
    };

    typedef NS_ENUM(NSUInteger, ExtraState) {
        ExtraStateBehaviorUUIDIndex,
        ExtraStateMutations,
    };

    switch ((EnumerationState)state->state) {
        case EnumerationStateUninitialized:
            state->state = EnumerationStateStarted;
            state->extra[ExtraStateBehaviorUUIDIndex] = 0;
            state->mutationsPtr = &state->extra[ExtraStateMutations]; // We're ignoring mutations, so mutationsPtr points to value that will not change (note: must not be NULL)

        case EnumerationStateStarted: {
            assert(count >= 1);
            objects[0] = nil;

            while (objects[0] == nil) {
                NSUInteger index = state->extra[ExtraStateBehaviorUUIDIndex];

                if (index == self.behaviorUUIDs.count) {
                    return 0;
                }

                objects[0] = [[BLMDataManager sharedManager] behaviorForUUID:self.behaviorUUIDs[index]];
                state->extra[ExtraStateBehaviorUUIDIndex] += 1;
            }

            state->itemsPtr = objects;
            
            return 1;
        }
    }
}

@end


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
    return [[BehaviorEnumerator alloc] initWithBehaviorUUIDs:self.behaviorUUIDs];
}

@end
