//
//  BLMBehavior.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/30/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSUInteger const BLMBehaviorNameMinimumLength;

extern NSString *const BLMBehaviorCreatedNotification;
extern NSString *const BLMBehaviorDeletedNotification;
extern NSString *const BLMBehaviorUpdatedNotification;

extern NSString *const BLMBehaviorOldBehaviorUserInfoKey;
extern NSString *const BLMBehaviorNewBehaviorUserInfoKey;


typedef NS_ENUM(NSInteger, BLMBehaviorProperty) {
    BLMBehaviorPropertyName,
    BLMBehaviorPropertyContinuous
};


@interface BLMBehavior : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSUUID *UUID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly, getter=isContinuous) BOOL continuous;

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name continuous:(BOOL)continuous;
- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty;

@end
