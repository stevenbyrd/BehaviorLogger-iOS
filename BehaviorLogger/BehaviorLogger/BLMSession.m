//
//  BLMSession.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMSession.h"
#import "BLMSchema.h"


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation BLMSession

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name condition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer schema:(BLMSchema *)schema timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions {
    NSParameterAssert(name.length > 0);
    NSParameterAssert(schema != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _uid = uid;
    _name = [name copy];
    _condition = [condition copy];
    _location = [location copy];
    _therapist = [therapist copy];
    _observer = [observer copy];
    _schema = schema;
    _timeLimitOptions = timeLimitOptions;

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUid:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"uid"]
                        name:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"]
                   condition:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"condition"]
                    location:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"location"]
                   therapist:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"therapist"]
                    observer:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"observer"]
                      schema:[aDecoder decodeObjectOfClass:[BLMSchema class] forKey:@"schema"]
            timeLimitOptions:[aDecoder decodeIntegerForKey:@"timeLimitOptions"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uid forKey:@"uid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.condition forKey:@"condition"];
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.therapist forKey:@"therapist"];
    [aCoder encodeObject:self.observer forKey:@"observer"];
    [aCoder encodeObject:self.schema forKey:@"schema"];
    [aCoder encodeInteger:self.timeLimitOptions forKey:@"timeLimitOptions"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

@end
