//
//  BLMProject.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMProject.h"
#import "BLMSession.h"
#import "BLMUtils.h"


NSUInteger const BLMProjectNameMinimumLength = 3;
NSUInteger const BLMProjectClientMinimumLength = 3;


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMProject

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name client:(NSString *)client defaultSessionConfiguration:(BLMSessionConfiguration *)defaultSessionConfiguration sessionByUid:(NSDictionary<NSNumber *, BLMSession *> *)sessionByUid {
    NSParameterAssert(name.length > BLMProjectNameMinimumLength);
    NSParameterAssert(client.length > BLMProjectClientMinimumLength);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _uid = uid;
    _name = [name copy];
    _client = [client copy];
    _defaultSessionConfiguration = (defaultSessionConfiguration ?: [[BLMSessionConfiguration alloc] initWitCondition:nil location:nil therapist:nil observer:nil timeLimit:-1 timeLimitOptions:0 behaviorList:@[]]);
    _sessionByUid = [sessionByUid copy];

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUid:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"uid"]
                        name:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"]
                      client:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"client"]
 defaultSessionConfiguration:[aDecoder decodeObjectOfClass:[BLMSessionConfiguration class] forKey:@"defaultSessionConfiguration"]
                sessionByUid:[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary<NSNumber *, BLMSession *> class], [NSNumber class], [BLMSession class]]] forKey:@"sessionByUid"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uid forKey:@"uid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.client forKey:@"client"];
    [aCoder encodeObject:self.defaultSessionConfiguration forKey:@"defaultSessionConfiguration"];
    [aCoder encodeObject:self.sessionByUid forKey:@"sessionByUid"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

#pragma mark Internal State

- (NSUInteger)hash {
    assert([NSThread isMainThread]);

    return (self.uid.hash
            ^ self.name.hash
            ^ self.client.hash
            ^ self.defaultSessionConfiguration.hash
            ^ self.sessionByUid.hash);
}


- (BOOL)isEqual:(id)object {
    assert([NSThread isMainThread]);

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BLMProject *project = (BLMProject *)object;

    return ([BLMUtils isNumber:self.uid equalToNumber:project.uid]
            && [BLMUtils isString:self.name equalToString:project.name]
            && [BLMUtils isString:self.client equalToString:project.client]
            && [BLMUtils isObject:self.defaultSessionConfiguration equalToObject:project.defaultSessionConfiguration]
            && [self.sessionByUid isEqualToDictionary:project.sessionByUid]);
}

@end
