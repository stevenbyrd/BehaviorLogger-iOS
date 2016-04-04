//
//  NSSet+CopyMinusObject.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 4/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "NSSet+CopyMinusObject.h"
#import "BLMUtils.h"

@implementation NSSet (CopyMinusObject)

- (nonnull NSSet *)setByRemovingObject:(nonnull id)object {
    assert(object != nil);

    if (![self containsObject:object]) {
        assert(NO);
        return self;
    }

    return [self filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *, id> * _Nullable bindings) {
        return ![evaluatedObject isEqual:object];
    }]];
}

@end
