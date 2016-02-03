//
//  BLMUtils.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/29/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BLMUtils : NSObject

+ (BOOL)isObject:(id)object1 equalToObject:(id)object2;
+ (BOOL)isString:(NSString *)string1 equalToString:(NSString *)string2;
+ (BOOL)isNumber:(NSNumber *)number1 equalToNumber:(NSNumber *)number2;
+ (BOOL)isDate:(NSDate *)date1 equalToDate:(NSDate *)date2;
+ (BOOL)isArray:(NSArray *)array1 equalToArray:(NSArray *)array2;
+ (BOOL)isDictionary:(NSDictionary *)dictionary1 equalToDictionary:(NSDictionary *)dictionary2;

@end
