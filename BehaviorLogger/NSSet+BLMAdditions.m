//
//  NSSet+BLMAdditions.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 4/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "NSSet+BLMAdditions.h"
#import "BLMUtils.h"


@implementation NSSet (BLMAdditions)

- (NSSet *)setByRemovingObject:(id)object {
    if (![self containsObject:object]) {
        assert(NO);
        return self;
    }

    return [self filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id __nonnull evaluatedObject, NSDictionary<NSString *, id> *__nullable bindings) {
        return ![evaluatedObject isEqual:object];
    }]];
}

@end
