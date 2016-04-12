//
//  NSOrderedSet+BLMAdditions.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 4/11/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "NSOrderedSet+BLMAdditions.h"


@implementation NSOrderedSet (BLMAdditions)

- (NSOrderedSet *)orderedSetByAddingObject:(id)object {
    NSUInteger index = [self indexOfObject:object];

    if (index != NSNotFound) {
        return self;
    }

    NSMutableOrderedSet *orderedSet = [self mutableCopy];
    [orderedSet addObject:object];

    return orderedSet;
}


- (NSOrderedSet *)orderedSetByRemovingObject:(id)object {
    NSUInteger index = [self indexOfObject:object];

    if (index == NSNotFound) {
        return self;
    }

    NSMutableOrderedSet *orderedSet = [self mutableCopy];
    [orderedSet removeObjectAtIndex:index];

    return orderedSet;
}


- (NSOrderedSet *)filteredOrderedSetUsingPredicate:(NSPredicate *)predicate {
    NSMutableIndexSet *removedIndexes = [NSMutableIndexSet indexSet];

    [self enumerateObjectsUsingBlock:^(id __nonnull object, NSUInteger index, BOOL *__nonnull stop) {
        if (![predicate evaluateWithObject:object]) {
            [removedIndexes addIndex:index];
        }
    }];

    if (removedIndexes.count == 0) {
        return self;
    }

    NSMutableOrderedSet *orderedSet = [self mutableCopy];
    [orderedSet removeObjectsAtIndexes:removedIndexes];

    return orderedSet;
}

@end
