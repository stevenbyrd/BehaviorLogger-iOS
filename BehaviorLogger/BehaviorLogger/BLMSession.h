//
//  BLMSession.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BLMBehavior;


typedef NSInteger BLMTimeInterval; // Represents an interval of time in seconds


typedef NS_OPTIONS(NSInteger, BLMTimeLimitOptions) {
    BLMTimeLimitOptionsPauseAutomatically,
    BLMTimeLimitOptionsChangeTimerColor,
    BLMTimeLimitOptionsPlayBeepSound,
};


typedef NS_ENUM(NSInteger, BLMSessionConfigurationProperty) {
    BLMSessionConfigurationPropertyCondition,
    BLMSessionConfigurationPropertyLocation,
    BLMSessionConfigurationPropertyTherapist,
    BLMSessionConfigurationPropertyObserver,
    BLMSessionConfigurationPropertyTimeLimit,
    BLMSessionConfigurationPropertyTimeLimitOptions,
    BLMSessionConfigurationPropertyBehaviorUUIDs
};


#pragma mark

@interface BLMSessionConfiguration : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *condition;
@property (nonatomic, copy, readonly) NSString *location;
@property (nonatomic, copy, readonly) NSString *therapist;
@property (nonatomic, copy, readonly) NSString *observer;
@property (nonatomic, assign, readonly) BLMTimeInterval timeLimit;
@property (nonatomic, assign, readonly) BLMTimeLimitOptions timeLimitOptions;
@property (nonatomic, copy, readonly) NSArray<NSUUID *> *behaviorUUIDs;

- (instancetype)initWitCondition:(NSString *)condition location:(NSString *)location therapist:(NSString *)therapist observer:(NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(NSArray<NSUUID *> *)behaviorUUIDs;
- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty; // @(BLMSessionConfigurationProperty) -> id

@end


#pragma mark

@interface BLMSession : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSUUID *UUID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) BLMSessionConfiguration *configuration;

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name configuration:(BLMSessionConfiguration *)configuration;

@end
