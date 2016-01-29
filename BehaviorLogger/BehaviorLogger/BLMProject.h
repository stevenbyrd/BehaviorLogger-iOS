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


@class BLMSchema;
@class BLMSession;


@interface BLMProject : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSNumber *uid;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *client;
@property (nonatomic, strong, readonly) BLMSchema *schema;
@property (nonatomic, copy, readonly) NSDictionary<NSNumber *, BLMSession *> *sessionByUid;

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name client:(NSString *)client schema:(BLMSchema *)schema sessionByUid:(NSDictionary<NSNumber *, BLMSession *> *)sessionByUid;

@end
