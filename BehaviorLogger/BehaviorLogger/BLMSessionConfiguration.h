//
//  BLMSessionConfiguration.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/9/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


extern NSString *const BLMSessionConfigurationCreatedNotification;
extern NSString *const BLMSessionConfigurationDeletedNotification;
extern NSString *const BLMSessionConfigurationUpdatedNotification;

extern NSString *const BLMSessionConfigurationOriginalSessionConfigurationUserInfoKey;
extern NSString *const BLMSessionConfigurationUpdatedSessionConfigurationUserInfoKey;


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

@class BLMBehavior;


@interface BLMSessionConfiguration : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSUUID *UUID;
@property (nullable, nonatomic, copy, readonly) NSString *condition;
@property (nullable, nonatomic, copy, readonly) NSString *location;
@property (nullable, nonatomic, copy, readonly) NSString *therapist;
@property (nullable, nonatomic, copy, readonly) NSString *observer;
@property (nonatomic, assign, readonly) BLMTimeInterval timeLimit;
@property (nonatomic, assign, readonly) BLMTimeLimitOptions timeLimitOptions;
@property (nonatomic, copy, readonly) NSOrderedSet<NSUUID *> *behaviorUUIDs;

- (instancetype)initWithUUID:(NSUUID *)UUID condition:(nullable NSString *)condition location:(nullable NSString *)location therapist:(nullable NSString *)therapist observer:(nullable NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(nullable NSOrderedSet<NSUUID *> *)behaviorUUIDs;
- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty; // @(BLMSessionConfigurationProperty) -> id

@end


NS_ASSUME_NONNULL_END
