//
//  NSSet+CopyMinusObject.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 4/3/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSSet<E> (CopyMinusObject)

- (nonnull NSSet<E> *)setByRemovingObject:(nonnull E)object;

@end
