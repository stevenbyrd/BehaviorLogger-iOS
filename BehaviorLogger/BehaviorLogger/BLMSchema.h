//
//  BLMSchema.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BLMMacro : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *behavior;
@property (nonatomic, assign, readonly, getter=isContinuous) BOOL continuous;

- (instancetype)initWithName:(NSString *)name behavior:(NSString *)behavior continuous:(BOOL)continuous;

@end


@interface BLMSchema : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSArray<BLMMacro *> *macros;

- (instancetype)initWithMacros:(NSArray<BLMMacro *> *)macros;

@end
