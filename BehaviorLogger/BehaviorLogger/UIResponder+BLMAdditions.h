//
//  UIResponder+FirstResponder.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIResponder (BLMAdditions)

+ (UIResponder *)currentFirstResponder;

@end
