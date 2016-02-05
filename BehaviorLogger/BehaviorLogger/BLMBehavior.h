//
//  BLMBehavior.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/30/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSUInteger const BLMBehaviorNameMinimumLength;


@interface BLMBehavior : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly, getter=isContinuous) BOOL continuous;

- (instancetype)initWithName:(NSString *)name continuous:(BOOL)continuous;

@end
