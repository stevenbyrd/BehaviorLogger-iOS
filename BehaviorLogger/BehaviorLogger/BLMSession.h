//
//  BLMSession.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BLMSession : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSUUID *UUID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) BLMSessionConfiguration *configuration;

- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name configuration:(BLMSessionConfiguration *)configuration;

@end
