//
//  BLMBehavior.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/30/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMBehavior.h"
#import "BLMUtils.h"


#pragma mark Constants

NSUInteger const BLMBehaviorNameMinimumLength = 3;

NSString *const BLMBehaviorCreatedNotification = @"BLMBehaviorCreatedNotification";;
NSString *const BLMBehaviorDeletedNotification = @"BLMBehaviorDeletedNotification";
NSString *const BLMBehaviorUpdatedNotification = @"BLMBehaviorUpdatedNotification";

NSString *const BLMBehaviorOriginalBehaviorUserInfoKey = @"BLMBehaviorOriginalBehaviorUserInfoKey";
NSString *const BLMBehaviorUpdatedBehaviorUserInfoKey = @"BLMBehaviorUpdatedBehaviorUserInfoKey";


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMBehavior

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name continuous:(BOOL)continuous {
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

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    return [self initWithUUID:[decoder decodeObjectForKey:@"UUID"]
                         name:[decoder decodeObjectForKey:@"name"]
                   continuous:[decoder decodeBoolForKey:@"continuous"]];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.UUID forKey:@"UUID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeBool:self.isContinuous forKey:@"continuous"];
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

    BLMBehavior *other = (BLMBehavior *)object;

    return ([BLMUtils isObject:self.UUID equalToObject:other.UUID]
            && [BLMUtils isString:self.name equalToString:other.name]
            && (self.isContinuous == other.isContinuous));
}

@end
