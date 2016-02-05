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


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMBehavior

- (instancetype)initWithName:(NSString *)name continuous:(BOOL)continuous {
    NSParameterAssert(name.length > 0);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _name = [name copy];
    _continuous = continuous;

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithName:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"]
                   continuous:[aDecoder decodeBoolForKey:@"continuous"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeBool:self.isContinuous forKey:@"continuous"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    assert([NSThread isMainThread]);

    return (self.name.hash
            ^ self.isContinuous);
}


- (BOOL)isEqual:(id)object {
    assert([NSThread isMainThread]);

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMBehavior *behavior = (BLMBehavior *)object;

    return ([BLMUtils isString:self.name equalToString:behavior.name]
            && (self.isContinuous == behavior.isContinuous));
}

@end
