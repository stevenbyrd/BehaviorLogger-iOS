//
//  Project.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "Project.h"
#import "Session.h"
#import "Schema.h"


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation Project

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name client:(NSString *)client schema:(Schema *)schema sessionByUid:(NSDictionary<NSNumber *, Session *> *)sessionByUid {
    NSParameterAssert(name.length > 0);
    NSParameterAssert(client.length > 0);
    NSParameterAssert(schema != nil);
    NSParameterAssert(sessionByUid != nil);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _uid = uid;
    _name = [name copy];
    _client = [client copy];
    _schema = schema;
    _sessionByUid = [sessionByUid copy];

    return self;
}

#pragma mark NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithUid:[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"uid"]
                        name:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"]
                      client:[aDecoder decodeObjectOfClass:[NSString class] forKey:@"client"]
                      schema:[aDecoder decodeObjectOfClass:[Schema class] forKey:@"schema"]
               sessionByUid:[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSDictionary<NSNumber *, Session *> class], [NSNumber class], [Session class]]] forKey:@"sessionByUid"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uid forKey:@"uid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.client forKey:@"client"];
    [aCoder encodeObject:self.schema forKey:@"schema"];
    [aCoder encodeObject:self.sessionByUid forKey:@"sessionByUid"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

@end
