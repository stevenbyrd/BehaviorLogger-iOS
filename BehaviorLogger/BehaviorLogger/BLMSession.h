//
//  BLMSession.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BLMSchema;


typedef NS_OPTIONS(NSInteger, BLMTimeLimitOptions) {
    BLMTimeLimitOptionsPauseAutomatically,
    BLMTimeLimitOptionsChangeTimerColor,
    BLMTimeLimitOptionsPlayBeepSound,
};


@interface BLMSession : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSNumber *uid;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *condition;
@property (nonatomic, copy, readonly) NSString *location;
@property (nonatomic, copy, readonly) NSString *therapist;
@property (nonatomic, copy, readonly) NSString *observer;
@property (nonatomic, strong, readonly) BLMSchema *schema;
@property (nonatomic, assign, readonly) BLMTimeLimitOptions timeLimitOptions;

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name condition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer schema:(BLMSchema *)schema timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions;

@end
