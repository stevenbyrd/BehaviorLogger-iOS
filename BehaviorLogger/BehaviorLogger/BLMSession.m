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

static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


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

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    return [self initWithUUID:[decoder decodeObjectForKey:@"UUID"]
                         name:[decoder decodeObjectForKey:@"name"]
                configuration:[decoder decodeObjectForKey:@"configuration"]];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.UUID forKey:@"UUID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.configuration forKey:@"configuration"];
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
            && [BLMUtils isObject:self.configuration equalToObject:other.configuration]);
}

@end
