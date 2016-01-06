//
//  Session.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


@class Schema;


typedef NS_OPTIONS(NSInteger, TimeLimitOptions) {
    TimeLimitOptionsPauseAutomatically,
    TimeLimitOptionsChangeTimerColor,
    TimeLimitOptionsPlayBeepSound,
};


@interface Session : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSNumber *uid;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *condition;
@property (nonatomic, copy, readonly) NSString *location;
@property (nonatomic, copy, readonly) NSString *therapist;
@property (nonatomic, copy, readonly) NSString *observer;
@property (nonatomic, strong, readonly) Schema *schema;
@property (nonatomic, assign, readonly) TimeLimitOptions timeLimitOptions;

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name condition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer schema:(Schema *)schema timeLimitOptions:(TimeLimitOptions)timeLimitOptions;

@end
