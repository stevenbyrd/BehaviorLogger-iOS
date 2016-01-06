//
//  Project.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


@class Schema;
@class Session;


@interface Project : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSNumber *uid;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *client;
@property (nonatomic, strong, readonly) Schema *schema;
@property (nonatomic, copy, readonly) NSDictionary<NSNumber *, Session *> *sessionByUid;

- (instancetype)initWithUid:(NSNumber *)uid name:(NSString *)name client:(NSString *)client schema:(Schema *)schema sessionByUid:(NSDictionary<NSNumber *, Session *> *)sessionByUid;

@end
