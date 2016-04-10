//
//  UIResponder+FirstResponder.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "UIResponder+BLMAdditions.h"


#pragma mark Constants

static __weak id __firstResponder;


#pragma mark

@implementation UIResponder (BLMAdditions)

+ (UIResponder *)currentFirstResponder {
    __firstResponder = nil;

    [[UIApplication sharedApplication] sendAction:@selector(_assignCurrentFirstResponder:) to:nil from:nil forEvent:nil];

    return __firstResponder;
}

- (void)_assignCurrentFirstResponder:(id)sender {
    __firstResponder = self;
}

@end