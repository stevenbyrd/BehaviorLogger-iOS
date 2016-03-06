//
//  BLMUtils.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/29/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMUtils.h"


@implementation BLMUtils

+ (BOOL)isObject:(id)object1 equalToObject:(id)object2 {
    return ((object1 == object2)
            || ((object1 != nil)
                && (object2 != nil)
                && [object1 isEqual:object2]));
}


+ (BOOL)isString:(NSString *)string1 equalToString:(NSString *)string2 {
    return ((string1 == string2)
            || ((string1 != nil)
                && (string2 != nil)
                && [string1 respondsToSelector:@selector(isEqualToString:)]
                && [string2 respondsToSelector:@selector(isEqualToString:)]
                && [string1 isEqualToString:string2]));
}


+ (BOOL)isNumber:(NSNumber *)number1 equalToNumber:(NSNumber *)number2 {
    return ((number1 == number2)
            || ((number1 != nil)
                && (number2 != nil)
                && [number1 respondsToSelector:@selector(isEqualToNumber:)]
                && [number2 respondsToSelector:@selector(isEqualToNumber:)]
                && [number1 isEqualToNumber:number2]));
}


+ (BOOL)isDate:(NSDate *)date1 equalToDate:(NSDate *)date2 {
    return ((date1 == date2)
            || ((date1 != nil)
                && (date2 != nil)
                && [date1 respondsToSelector:@selector(isEqualToDate:)]
                && [date2 respondsToSelector:@selector(isEqualToDate:)]
                && [date1 isEqualToDate:date2]));
}


+ (BOOL)isArray:(NSArray *)array1 equalToArray:(NSArray *)array2 {
    return ((array1 == array2)
            || ((array1 != nil)
                && (array2 != nil)
                && [array1 respondsToSelector:@selector(isEqualToArray:)]
                && [array2 respondsToSelector:@selector(isEqualToArray:)]
                && [array1 isEqualToArray:array2]));
}


+ (BOOL)isDictionary:(NSDictionary *)dictionary1 equalToDictionary:(NSDictionary *)dictionary2 {
    return ((dictionary1 == dictionary2)
            || ((dictionary1 != nil)
                && (dictionary2 != nil)
                && [dictionary1 respondsToSelector:@selector(isEqualToDictionary:)]
                && [dictionary2 respondsToSelector:@selector(isEqualToDictionary:)]
                && [dictionary1 isEqualToDictionary:dictionary2]));

}


+ (id)objectFromDictionary:(NSDictionary *)dictionary forKey:(id<NSCopying>)key nullValue:(id)nullValue defaultValue:(id)defaultValue {
    id value = dictionary[key];

    if ([self isObject:value equalToObject:[NSNull null]]) {
        return nullValue;
    }

    if (value == nil) {
        return defaultValue;
    }

    return value;
}


+ (NSInteger)integerFromDictionary:(NSDictionary *)dictionary forKey:(id<NSCopying>)key defaultValue:(NSInteger)defaultValue {
    NSNumber *value = dictionary[key];

    if ([self isObject:value equalToObject:[NSNull null]] || (value == nil)) {
        return defaultValue;
    }

    return value.integerValue;
}


+ (double)doubleFromDictionary:(NSDictionary *)dictionary forKey:(id<NSCopying>)key defaultValue:(double)defaultValue {
    NSNumber *value = dictionary[key];

    if ([self isObject:value equalToObject:[NSNull null]] || (value == nil)) {
        return defaultValue;
    }

    return value.doubleValue;
}


+ (BOOL)boolFromDictionary:(NSDictionary *)dictionary forKey:(id<NSCopying>)key defaultValue:(BOOL)defaultValue {
    NSNumber *value = dictionary[key];

    if ([self isObject:value equalToObject:[NSNull null]] || (value == nil)) {
        return defaultValue;
    }

    return value.boolValue;
}

@end
