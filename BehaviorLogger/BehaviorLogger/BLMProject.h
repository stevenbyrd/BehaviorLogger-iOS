//
//  BLMProject.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSUInteger const BLMProjectNameMinimumLength;
extern NSUInteger const BLMProjectClientMinimumLength;

extern NSString *const BLMProjectCreatedNotification;
extern NSString *const BLMProjectDeletedNotification;
extern NSString *const BLMProjectUpdatedNotification;

extern NSString *const BLMProjectOldProjectUserInfoKey;
extern NSString *const BLMProjectNewProjectUserInfoKey;


typedef NS_ENUM(NSUInteger, BLMProjectProperty) {
    BLMProjectPropertyName,
    BLMProjectPropertyClient,
    BLMProjectPropertySessionConfigurationUUID,
    BLMProjectPropertySessionByUUID
};


@class BLMSession;
@class BLMSessionConfiguration;


@interface BLMProject : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSUUID *UUID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *client;
@property (nonatomic, strong, readonly) NSUUID *sessionConfigurationUUID;
@property (nonatomic, copy, readonly) NSDictionary<NSUUID *, BLMSession *> *sessionByUUID;

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name client:(NSString *)client sessionConfigurationUUID:(NSUUID *)sessionConfigurationUUID sessionByUUID:(NSDictionary<NSUUID *, BLMSession *> *)sessionByUUID;
- (instancetype)copyWithUpdatedValuesByProperty:(NSDictionary<NSNumber *, id> *)valuesByProperty;

@end
