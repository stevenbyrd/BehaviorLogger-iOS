//
//  NSOrderedSet+BLMAdditions.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 4/11/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface NSOrderedSet<ObjectType> (BLMAdditions)

- (NSOrderedSet<ObjectType> *)orderedSetByAddingObject:(ObjectType)object;
- (NSOrderedSet<ObjectType> *)orderedSetByRemovingObject:(ObjectType)object;
- (NSOrderedSet<ObjectType> *)filteredOrderedSetUsingPredicate:(NSPredicate *)predicate;

@end


NS_ASSUME_NONNULL_END
