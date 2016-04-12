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
    BLMSessionPropertyName,
    BLMSessionPropertySessionConfigurationUUID
};


#pragma mark

@interface BLMSession : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSUUID *UUID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSUUID *sessionConfigurationUUID;

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name sessionConfigurationUUID:(NSUUID *)sessionConfigurationUUID;
- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty;

@end


NS_ASSUME_NONNULL_END
