//
//  UIResponder+FirstResponder.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


@interface UIResponder (BLMAdditions)

+ (nullable UIResponder *)currentFirstResponder;

@end


NS_ASSUME_NONNULL_END
