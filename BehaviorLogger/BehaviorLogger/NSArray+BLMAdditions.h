//
//  NSArray+BLMAdditions.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/8/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface NSArray<E> (BLMAdditions)

- (NSArray<E> *)arrayByRemovingObject:(E)object;

@end


NS_ASSUME_NONNULL_END
