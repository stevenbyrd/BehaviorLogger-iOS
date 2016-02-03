//
//  BLMInsetTextField.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 2/1/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMPaddedTextField.h"


@implementation BLMPaddedTextField

- (instancetype)initWithHorizontalPadding:(CGFloat)horizontalPadding verticalPadding:(CGFloat)verticalPadding {
    self = [super initWithFrame:CGRectZero];

    if (self == nil) {
        return nil;
    }

    _horizontalPadding = horizontalPadding;
    _verticalPadding = verticalPadding;
    
    return self;
}


- (CGRect)textRectForBounds:(CGRect)bounds { // placeholder position
    return CGRectInset(bounds, self.horizontalPadding, self.verticalPadding);
}


- (CGRect)editingRectForBounds:(CGRect)bounds { // text position
    return CGRectInset(bounds, self.horizontalPadding, self.verticalPadding);
}

@end
