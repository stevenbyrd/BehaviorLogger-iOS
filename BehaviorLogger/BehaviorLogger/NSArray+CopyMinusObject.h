//
//  NSArray+CopyMinusObject.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/8/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<E> (CopyMinusObject)

- (NSArray<E> *)arrayByRemovingObject:(E)object;

@end
