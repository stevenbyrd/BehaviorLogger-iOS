//
//  UIResponder+FirstResponder.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "UIResponder+FirstResponder.h"


static __weak id __firstResponder;


@implementation UIResponder (FirstResponder)

+ (UIResponder *)currentFirstResponder {
    __firstResponder = nil;

    [[UIApplication sharedApplication] sendAction:@selector(_assignCurrentFirstResponder:) to:nil from:nil forEvent:nil];

    return __firstResponder;
}

- (void)_assignCurrentFirstResponder:(id)sender {
    __firstResponder = self;
}

@end