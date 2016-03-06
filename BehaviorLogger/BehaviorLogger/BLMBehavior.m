//
//  BLMBehavior.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/30/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMBehavior.h"
#import "BLMUtils.h"


NSUInteger const BLMBehaviorNameMinimumLength = 3;

NSString *const BLMBehaviorCreatedNotification = @"BLMBehaviorCreatedNotification";;
NSString *const BLMBehaviorDeletedNotification = @"BLMBehaviorDeletedNotification";
NSString *const BLMBehaviorUpdatedNotification = @"BLMBehaviorUpdatedNotification";

NSString *const BLMBehaviorOldBehaviorUserInfoKey = @"BLMBehaviorOldBehaviorUserInfoKey";
NSString *const BLMBehaviorNewBehaviorUserInfoKey = @"BLMBehaviorNewBehaviorUserInfoKey";


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMBehavior

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name continuous:(BOOL)continuous {
    assert(UUID != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _UUID = UUID;
    _name = [name copy];
    _continuous = continuous;

    return self;
}


- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty {
    return [[BLMBehavior alloc] initWithUUID:self.UUID
                                        name:[BLMUtils objectFromDictionary:valuesByProperty forKey:@(BLMBehaviorPropertyName) nullValue:nil defaultValue:self.name]
                                  continuous:[BLMUtils boolFromDictionary:valuesByProperty forKey:@(BLMBehaviorPropertyContinuous) defaultValue:self.isContinuous]];
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUUID:[aDecoder decodeObjectForKey:@"UUID"]
                         name:[aDecoder decodeObjectForKey:@"name"]
                   continuous:[aDecoder decodeBoolForKey:@"continuous"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.UUID forKey:@"UUID"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeBool:self.isContinuous forKey:@"continuous"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    return self.UUID.hash;
}


- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMBehavior *other = (BLMBehavior *)object;

    return ([BLMUtils isObject:self.UUID equalToObject:other.UUID]
            && [BLMUtils isString:self.name equalToString:other.name]
            && (self.isContinuous == other.isContinuous));
}

@end
