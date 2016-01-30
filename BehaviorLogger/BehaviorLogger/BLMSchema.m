//
//  BLMSchema.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMSchema.h"
#import "BLMUtils.h"


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMMacro

- (instancetype)initWithName:(NSString *)name behavior:(NSString *)behavior continuous:(BOOL)continuous {
    NSParameterAssert(name.length > 0);
    NSParameterAssert(behavior.length > 0);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _name = [name copy];
    _behavior = [behavior copy];
    _continuous = continuous;

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithName:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"]
                     behavior:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"behavior"]
                   continuous:[aDecoder decodeBoolForKey:@"continuous"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.behavior forKey:@"behavior"];
    [aCoder encodeBool:self.isContinuous forKey:@"continuous"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    assert([NSThread isMainThread]);
    
    return (self.name.hash
            ^ self.behavior.hash
            ^ self.isContinuous);
}


- (BOOL)isEqual:(id)object {
    assert([NSThread isMainThread]);

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMMacro *macro = (BLMMacro *)object;

    return ([BLMUtils isString:self.name equalToString:macro.name]
            && [BLMUtils isString:self.behavior equalToString:macro.behavior]
            && (self.isContinuous == macro.isContinuous));
}

@end


#pragma mark

@implementation BLMSchema

- (instancetype)initWithMacros:(NSArray<BLMMacro *> *)macros {
    NSParameterAssert(macros != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _macros = [macros copy];

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithMacros:[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSArray<BLMMacro *> class], [BLMMacro class]]] forKey:@"macros"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.macros forKey:@"macros"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    assert([NSThread isMainThread]);

    return self.macros.hash;
}


- (BOOL)isEqual:(id)object {
    assert([NSThread isMainThread]);

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMSchema *schema = (BLMSchema *)object;

    return [self.macros isEqualToArray:schema.macros];
}

@end
