//
//  BLMViewUtils.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/30/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMViewUtils.h"


#pragma mark

CGRect CGRectPixelAlign(CGRect rect) {
    return (CGRect) {
        .origin = {
            .x = (NSInteger)((CGRectGetMinX(rect) + 0.5) / 1),
            .y = (NSInteger)((CGRectGetMinY(rect) + 0.5) / 1)
        },
        .size = {
            .width = (NSInteger)((CGRectGetWidth(rect) + 0.5) / 1),
            .height = (NSInteger)((CGRectGetHeight(rect) + 0.5) / 1)
        }
    };
}


CGPoint CGRectGetCenter(CGRect rect) {
    return (CGPoint) {
        .x = CGRectGetMidX(rect),
        .y = CGRectGetMidY(rect)
    };
}


#pragma mark

@implementation BLMViewUtils

#pragma mark Colors

+ (UIColor *)colorForHexCode:(BLMColorHexCode)hexCode {
    return [self colorForHexCode:hexCode alpha:1.0];
}

+ (UIColor *)colorForHexCode:(BLMColorHexCode)hexCode alpha:(CGFloat)alpha {
    CGFloat red = ((hexCode & 0xFF0000) >> 16) / 255.0;
    CGFloat green = ((hexCode & 0x00FF00) >> 8) / 255.0;
    CGFloat blue = (hexCode & 0x0000FF) / 255.0;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

#pragma mark String Attributes

+ (NSParagraphStyle *)centerAlignedParagraphStyle {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;

    return paragraphStyle;
}

#pragma mark Images

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGRect rect = CGRectMake(0.0, 0.0, 1.0, 1.0);
    CGFloat alpha = 1.0;
    BOOL success = [color getRed:NULL green:NULL blue:NULL alpha:&alpha];

    if (!success) {
        alpha = 0.5;
    }

    UIGraphicsBeginImageContextWithOptions(rect.size, alpha >= 1.0, scale);

    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];

    [color setFill];
    [path fill];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}


+ (UIImage *)infoImageWithColor:(UIColor *)color {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat inset = 0.5;
    CGSize size = CGSizeMake(26.0 + (3.0 * inset), 26.0 + (3.0 * inset));

    UIGraphicsBeginImageContextWithOptions(size, NO, scale);

    CGRect circleRect = CGRectMake(0.0 + inset, 0.0 + inset, size.width - (2.0 * inset), size.height - (2.0 * inset));
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:circleRect];

    path.lineWidth = 1.0;

    [color setStroke];
    [path stroke];

    NSDictionary *attributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:20.0], NSParagraphStyleAttributeName : [BLMViewUtils centerAlignedParagraphStyle], NSForegroundColorAttributeName : color};
    NSAttributedString *styledText = [[NSAttributedString alloc] initWithString:@"i" attributes:attributes];

    circleRect.origin.y = 1.0 + round(circleRect.size.height - styledText.size.height) / 2.0;

    [styledText drawInRect:circleRect];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}


+ (UIImage *)plusSignImageWithColor:(UIColor *)color {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat lineWidth = 5.0;
    CGFloat inset = (lineWidth / 2.0);
    CGSize size = CGSizeMake(60.0, 60.0);

    UIGraphicsBeginImageContextWithOptions(size, NO, scale);

    CGRect circleRect = CGRectMake(0.0 + inset, 0.0 + inset, size.width - (2.0 * inset), size.height - (2.0 * inset));
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:circleRect];

    path.lineWidth = lineWidth;

    [color setStroke];
    [path stroke];

    path = [UIBezierPath bezierPath];

    path.lineWidth = lineWidth;

    [path moveToPoint:CGPointMake((size.width / 4.0), (size.height / 2.0))];
    [path addLineToPoint:CGPointMake(((3 * size.width) / 4.0), (size.height / 2.0))];

    [path moveToPoint:CGPointMake((size.width / 2.0), (size.height / 4.0))];
    [path addLineToPoint:CGPointMake((size.width / 2.0), ((3 * size.height) / 4.0))];

    [path stroke];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


+ (UIImage *)acceptImageWithColor:(UIColor *)color {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(31.5, 21.5);

    UIGraphicsBeginImageContextWithOptions(size, NO, scale);

    UIBezierPath *path = [UIBezierPath bezierPath];

    [path moveToPoint:CGPointMake(0.0, size.height / 2.0)];
    [path addLineToPoint:CGPointMake(11.25, size.height - 0.5)];
    [path addLineToPoint:CGPointMake(size.width, 0.0)];

    path.lineWidth = 1.0;

    [color setStroke];
    [path stroke];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}


+ (UIImage *)rejectImageWithColor:(UIColor *)color {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(22.5, 22.5);

    UIGraphicsBeginImageContextWithOptions(size, NO, scale);

    UIBezierPath *path = [UIBezierPath bezierPath];

    [path moveToPoint:CGPointMake(0.0, 0.0)];
    [path addLineToPoint:CGPointMake(size.width, size.height)];

    [path moveToPoint:CGPointMake(size.width, 0.0)];
    [path addLineToPoint:CGPointMake(0.0, size.height)];

    path.lineWidth = 1.0;

    [color setStroke];
    [path stroke];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}


+ (UIImage *)deleteItemImageWithBackgroundColor:(UIColor *)backgroundColor diameter:(CGFloat)diameter {
    CGSize canvasSize = CGSizeMake((diameter + 2.0), (diameter + 2.0));
    CGRect frame = CGRectMake(((canvasSize.width - diameter) / 2.0), ((canvasSize.height - diameter) / 2.0), diameter, diameter);

    UIGraphicsBeginImageContextWithOptions(canvasSize, NO, [UIScreen mainScreen].scale);

    [backgroundColor setFill];
    [[self colorForHexCode:BLMColorHexCodeWhite] setStroke];

    UIBezierPath *path = [UIBezierPath bezierPath];

    [path addArcWithCenter:CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame)) radius:(diameter * 0.5) startAngle:0 endAngle:(2 * M_PI) clockwise:NO];
    [path closePath];
    [path fill];

    path.lineWidth = 1.0;

    CGFloat leftX = CGRectGetMinX(frame) + ((CGRectGetMaxX(frame) - CGRectGetMinX(frame)) * 0.25);
    CGFloat rightX = CGRectGetMinX(frame) + ((CGRectGetMaxX(frame) - CGRectGetMinX(frame)) * 0.75);
    CGFloat topY = CGRectGetMinY(frame) + ((CGRectGetMaxY(frame) - CGRectGetMinY(frame)) * 0.25);
    CGFloat bottomY = CGRectGetMinY(frame) + ((CGRectGetMaxY(frame) - CGRectGetMinY(frame)) * 0.75);

    [path moveToPoint:CGPointMake(leftX, topY)];
    [path addLineToPoint:CGPointMake(rightX, bottomY)];
    [path moveToPoint:CGPointMake(leftX, bottomY)];
    [path addLineToPoint:CGPointMake(rightX, topY)];
    [path stroke];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

#pragma mark Layout Constraints

+ (NSLayoutConstraint *)constraintWithItem:(id)view attribute:(NSLayoutAttribute)attribute equalToConstant:(CGFloat)constant {
    NSLayoutConstraint *constraint = nil;

    switch (attribute) {
        case NSLayoutAttributeWidth:
        case NSLayoutAttributeHeight: {
            constraint = [NSLayoutConstraint constraintWithItem:view attribute:attribute relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:constant];
            break;
        }

        case NSLayoutAttributeLeft:
        case NSLayoutAttributeRight:
        case NSLayoutAttributeLeading:
        case NSLayoutAttributeTrailing:
        case NSLayoutAttributeCenterX:
        case NSLayoutAttributeLeftMargin:
        case NSLayoutAttributeRightMargin:
        case NSLayoutAttributeLeadingMargin:
        case NSLayoutAttributeTrailingMargin:
        case NSLayoutAttributeCenterXWithinMargins: {
            constraint = [NSLayoutConstraint constraintWithItem:view attribute:attribute relatedBy:NSLayoutRelationEqual toItem:[view superview] attribute:NSLayoutAttributeLeft multiplier:1.0 constant:constant];
            break;
        }

        case NSLayoutAttributeTop:
        case NSLayoutAttributeBottom:
        case NSLayoutAttributeCenterY:
        case NSLayoutAttributeLastBaseline:
        case NSLayoutAttributeFirstBaseline:
        case NSLayoutAttributeTopMargin:
        case NSLayoutAttributeBottomMargin:
        case NSLayoutAttributeCenterYWithinMargins: {
            constraint = [NSLayoutConstraint constraintWithItem:view attribute:attribute relatedBy:NSLayoutRelationEqual toItem:[view superview] attribute:NSLayoutAttributeTop multiplier:1.0 constant:constant];
            break;
        }

        case NSLayoutAttributeNotAnAttribute: {
            assert(0);
            break;
        }
    }

    return constraint;
}


+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute equalToItem:(id)view2 constant:(CGFloat)constant {
    return [self constraintWithItem:view1 attribute:attribute equalToItem:view2 attribute:attribute constant:constant];
}


+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute1 equalToItem:(id)view2 attribute:(NSLayoutAttribute)attribute2 constant:(CGFloat)constant {
    return [NSLayoutConstraint constraintWithItem:view1 attribute:attribute1 relatedBy:NSLayoutRelationEqual toItem:view2 attribute:attribute2 multiplier:1.0 constant:constant];
}

+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute1 greaterThanOrEqualToItem:(id)view2 attribute:(NSLayoutAttribute)attribute2 constant:(CGFloat)constant {
    return [NSLayoutConstraint constraintWithItem:view1 attribute:attribute1 relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:view2 attribute:attribute2 multiplier:1.0 constant:constant];
}

+ (NSLayoutConstraint *)constraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attribute1 lessThanOrEqualToItem:(id)view2 attribute:(NSLayoutAttribute)attribute2 constant:(CGFloat)constant {
    return [NSLayoutConstraint constraintWithItem:view1 attribute:attribute1 relatedBy:NSLayoutRelationLessThanOrEqual toItem:view2 attribute:attribute2 multiplier:1.0 constant:constant];
}


+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 centeredOnItem:(id)view2 {
    return @[[self constraintWithItem:view1 attribute:NSLayoutAttributeCenterX equalToItem:view2 constant:0.0], [self constraintWithItem:view1 attribute:NSLayoutAttributeCenterY equalToItem:view2 constant:0.0]];
}


+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 equalSizedToItem:(id)view2 {
    return @[[self constraintWithItem:view1 attribute:NSLayoutAttributeWidth equalToItem:view2 constant:0.0], [self constraintWithItem:view1 attribute:NSLayoutAttributeHeight equalToItem:view2 constant:0.0]];
}


+ (NSArray<NSLayoutConstraint *> *)constraintsForItem:(id)view1 equalToItem:(id)view2 {
    return @[[self constraintWithItem:view1 attribute:NSLayoutAttributeLeft equalToItem:view2 constant:0.0],
             [self constraintWithItem:view1 attribute:NSLayoutAttributeRight equalToItem:view2 constant:0.0],
             [self constraintWithItem:view1 attribute:NSLayoutAttributeTop equalToItem:view2 constant:0.0],
             [self constraintWithItem:view1 attribute:NSLayoutAttributeBottom equalToItem:view2 constant:0.0]];
}

@end
