//
//  Schema.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "Schema.h"


static NSString *const ArchiveVersionKey = @"ArchiveVersionKey";


typedef NS_ENUM(NSInteger, ArchiveVersion) {
    ArchiveVersionUnknown,
    ArchiveVersionLatest
};


#pragma mark

@implementation Macro

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

@end


#pragma mark 

@implementation Schema

- (instancetype)initWithMacros:(NSArray<Macro *> *)macros {
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
    return [self initWithMacros:[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSArray<Macro *> class], [Macro class]]] forKey:@"macros"]];
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.macros forKey:@"macros"];
    [aCoder encodeInteger:ArchiveVersionLatest forKey:ArchiveVersionKey];
}

@end
