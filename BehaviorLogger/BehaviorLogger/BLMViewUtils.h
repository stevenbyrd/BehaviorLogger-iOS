//
//  BLMViewUtils.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/30/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, BLMColorHexCode) {
    BLMColorHexCodeDefaultBackground = 0xe4e4e6,
    BLMColorHexCodeDarkBackground = 0xb4b4b4,
    BLMColorHexCodeDarkBorder = 0x0d0d0d,
    BLMColorHexCodeBlue = 0x1c00cf,
    BLMColorHexCodeBrown = 0x643820,
    BLMColorHexCodeGreen = 0x007400,
    BLMColorHexCodeRed = 0xc41a16,
    BLMColorHexCodePurple = 0x9529f7
};


@interface BLMViewUtils : NSObject

#pragma mark Colors

+ (UIColor *)colorWithHexValue:(uint32_t)hexValue alpha:(CGFloat)alpha;

#pragma mark Images

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)infoImageWithColor:(UIColor *)color;
+ (UIImage *)plusSignImageWithColor:(UIColor *)color;
+ (UIImage *)acceptImageWithColor:(UIColor *)color;
+ (UIImage *)rejectImageWithColor:(UIColor *)color;
+ (UIImage *)deleteItemImageWithBackgroundColor:(UIColor *)backgroundColor diameter:(CGFloat)diameter;

#pragma mark Layout Constraints

+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute equalToConstant:(CGFloat)constant;
+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute equalToItem:(id)view2 constant:(CGFloat)constant;
+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute1 equalToItem:(id)view2 attribute:(NSLayoutAttribute)attribute2 constant:(CGFloat)constant;

+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute1 greaterThanOrEqualToItem:(id)view2 attribute:(NSLayoutAttribute)attribute2 constant:(CGFloat)constant;
+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute1 lessThanOrEqualToItem:(id)view2 attribute:(NSLayoutAttribute)attribute2 constant:(CGFloat)constant;

+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 centeredOnItem:(id)view2;
+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 equalSizedToItem:(id)view2;
+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 equalToItem:(id)view2;

@end
