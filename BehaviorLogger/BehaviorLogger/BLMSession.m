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

- (instancetype)initWitCondition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorList:(NSArray<BLMBehavior *> *)behaviorList {
    NSParameterAssert(behaviorList != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _condition = [condition copy];
    _location = [location copy];
    _therapist = [therapist copy];
    _observer = [observer copy];
    _timeLimitOptions = timeLimitOptions;
    _behaviorList = [behaviorList copy];

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWitCondition:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"condition"]
                         location:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"location"]
                        therapist:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"therapist"]
                         observer:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"observer"]
                 timeLimitOptions:[aDecoder decodeIntegerForKey:@"timeLimitOptions"]
                           behaviorList:[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSArray<BLMBehavior *> class], [BLMBehavior class]]] forKey:@"behaviorList"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.condition forKey:@"condition"];
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.therapist forKey:@"therapist"];
    [aCoder encodeObject:self.observer forKey:@"observer"];
    [aCoder encodeInteger:self.timeLimitOptions forKey:@"timeLimitOptions"];
    [aCoder encodeObject:self.behaviorList forKey:@"behaviorList"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    assert([NSThread isMainThread]);
    
    return (self.condition.hash
            ^ self.location.hash
            ^ self.observer.hash
            ^ self.timeLimitOptions
            ^ self.behaviorList.hash);
}


- (BOOL)isEqual:(id)object {
    assert([NSThread isMainThread]);

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMSessionConfiguration *configuration = (BLMSessionConfiguration *)object;

    return ([BLMUtils isString:self.condition equalToString:configuration.condition]
            && [BLMUtils isString:self.location equalToString:configuration.location]
            && [BLMUtils isString:self.observer equalToString:configuration.observer]
            && [BLMUtils isArray:self.behaviorList equalToArray:configuration.behaviorList]
            && (self.timeLimitOptions == configuration.timeLimitOptions));
}

@end


#pragma mark

@implementation BLMSession

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name configuration:(BLMSessionConfiguration *)configuration {
    NSParameterAssert(uid != nil);
    NSParameterAssert(name.length > 0);
    NSParameterAssert(configuration != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _uid = uid;
    _name = [name copy];
    _configuration = configuration;

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUid:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"uid"]
                        name:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"]
               configuration:[aDecoder decodeObjectOfClass:[BLMSessionConfiguration class] forKey:@"configuration"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uid forKey:@"uid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.configuration forKey:@"configuration"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    assert([NSThread isMainThread]);

    return self.uid.hash;
}


- (BOOL)isEqual:(id)object {
    assert([NSThread isMainThread]);

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMSession *session = (BLMSession *)object;

    return ([BLMUtils isNumber:self.uid equalToNumber:session.uid]
            && [BLMUtils isString:self.name equalToString:session.name]
            && [BLMUtils isObject:self.configuration equalToObject:session.configuration]);
}

@end
