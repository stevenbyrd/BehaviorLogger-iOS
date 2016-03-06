//
//  BLMUtils.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/29/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BLMUtils : NSObject

+ (BOOL)isObject:(nullable id)object1 equalToObject:(nullable id)object2;
+ (BOOL)isString:(nullable NSString *)string1 equalToString:(nullable NSString *)string2;
+ (BOOL)isNumber:(nullable NSNumber *)number1 equalToNumber:(nullable NSNumber *)number2;
+ (BOOL)isDate:(nullable NSDate *)date1 equalToDate:(nullable NSDate *)date2;
+ (BOOL)isArray:(nullable NSArray *)array1 equalToArray:(nullable NSArray *)array2;
+ (BOOL)isDictionary:(nullable NSDictionary *)dictionary1 equalToDictionary:(nullable NSDictionary *)dictionary2;

+ (nullable id)objectFromDictionary:(nonnull NSDictionary *)dictionary forKey:(nonnull id<NSCopying>)key nullValue:(nullable id)nullValue defaultValue:(nullable id)defaultValue;
+ (NSInteger)integerFromDictionary:(nonnull NSDictionary *)dictionary forKey:(nonnull id<NSCopying>)key defaultValue:(NSInteger)defaultValue;
+ (double)doubleFromDictionary:(nonnull NSDictionary *)dictionary forKey:(nonnull id<NSCopying>)key defaultValue:(double)defaultValue;
+ (BOOL)boolFromDictionary:(nonnull NSDictionary *)dictionary forKey:(nonnull id<NSCopying>)key defaultValue:(BOOL)defaultValue;

@end
