//
//  BLMSession.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


extern NSString *const BLMSessionCreatedNotification;
extern NSString *const BLMSessionDeletedNotification;
extern NSString *const BLMSessionUpdatedNotification;

extern NSString *const BLMSessionOriginalSessionUserInfoKey;
extern NSString *const BLMSessionUpdatedSessionUserInfoKey;


typedef NS_ENUM(NSInteger, BLMSessionProperty) {
    BLMSessionPropertyStartDate,
    BLMSessionPropertyEndDate
};


#pragma mark

@interface BLMSession : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSUUID *UUID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSUUID *configurationUUID;
@property (nonatomic, strong, readonly) NSDate *creationDate;
@property (nonatomic, strong, readonly) NSDate *startDate;
@property (nonatomic, strong, readonly) NSDate *endDate;

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name configurationUUID:(NSUUID *)configurationUUID creationDate:(NSDate *)creationDate startDate:(nullable NSDate *)startDate endDate:(nullable NSDate *)endDate;
- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty;

@end


NS_ASSUME_NONNULL_END
