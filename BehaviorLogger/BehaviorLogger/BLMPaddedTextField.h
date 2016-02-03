//
//  BLMInsetTextField.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/1/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BLMPaddedTextField : UITextField

@property (nonatomic, assign, readonly) CGFloat horizontalPadding;
@property (nonatomic, assign, readonly) CGFloat verticalPadding;

- (instancetype)initWithHorizontalPadding:(CGFloat)horizontalPadding verticalPadding:(CGFloat)verticalPadding;

@end
