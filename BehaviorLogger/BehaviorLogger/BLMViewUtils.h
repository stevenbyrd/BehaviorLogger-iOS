//
//  BLMViewUtils.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/30/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface BLMViewUtils : NSObject

#pragma mark Colors

+ (UIColor *)colorWithHexValue:(uint32_t)hexValue alpha:(CGFloat)alpha;

#pragma mark Images

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)infoImageWithColor:(UIColor *)color;
+ (UIImage *)acceptImageWithColor:(UIColor *)color;
+ (UIImage *)rejectImageWithColor:(UIColor *)color;
+ (UIImage *)deleteItemImageWithBackgroundColor:(UIColor *)backgroundColor;

#pragma mark Layout Constraints

+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute equalToConstant:(CGFloat)constant;
+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute equalToItem:(id)view2 constant:(CGFloat)constant;
+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute1 equalToItem:(id)view2 attribute:(NSLayoutAttribute)attribute2 constant:(CGFloat)constant;

+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 centeredOnItem:(id)view2;
+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 equalSizedToItem:(id)view2;
+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 equalToItem:(id)view2;

@end
