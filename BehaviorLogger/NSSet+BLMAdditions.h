//
//  NSSet+BLMAdditions.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 4/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface NSSet<E> (BLMAdditions)

- (NSSet<E> *)setByRemovingObject:(E)object;

@end


NS_ASSUME_NONNULL_END
