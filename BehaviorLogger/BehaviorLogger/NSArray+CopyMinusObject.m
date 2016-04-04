//
//  NSArray+CopyMinusObject.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/8/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "NSArray+CopyMinusObject.h"


@implementation NSArray (CopyMinusObject)

- (nonnull NSArray *)arrayByRemovingObject:(nonnull id)object {
    NSUInteger index = [self indexOfObject:object];
    assert(index != NSNotFound);

    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.count)];
    [indexSet removeIndex:index];

    return [self objectsAtIndexes:indexSet];
}

@end
