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


@interface BLMSessionConfiguration : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *condition;
@property (nonatomic, copy, readonly) NSString *location;
@property (nonatomic, copy, readonly) NSString *therapist;
@property (nonatomic, copy, readonly) NSString *observer;
@property (nonatomic, assign, readonly) BLMTimeLimitOptions timeLimitOptions;
@property (nonatomic, strong, readonly) BLMSchema *schema;

- (instancetype)initWitCondition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions schema:(BLMSchema *)schema;

@end


@interface BLMSession : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSNumber *uid;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) BLMSessionConfiguration *configuration;

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name configuration:(BLMSessionConfiguration *)configuration;

@end
