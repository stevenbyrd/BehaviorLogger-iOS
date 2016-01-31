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

@end
