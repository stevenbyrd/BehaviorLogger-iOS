//
//  BLMTextField.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/11/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMTextField.h"
#import "BLMViewUtils.h"


@implementation BLMTextField

@dynamic delegate;

- (instancetype)initWithHorizontalPadding:(CGFloat)horizontalPadding verticalPadding:(CGFloat)verticalPadding {
    self = [super initWithFrame:CGRectZero];

    if (self == nil) {
        return nil;
    }
    
    self.backgroundColor = [BLMViewUtils colorForHexCode:BLMColorHexCodeWhite];

    _horizontalPadding = horizontalPadding;
    _verticalPadding = verticalPadding;

    return self;
}


- (CGRect)textRectForBounds:(CGRect)bounds { // Placeholder position
    return CGRectPixelAlign(CGRectInset(bounds, (self.horizontalPadding - 1.0), self.verticalPadding)); // -1.0 pixel workaround for NSAttributedString size bug
}


- (CGRect)editingRectForBounds:(CGRect)bounds { // Text position
    return CGRectPixelAlign(CGRectInset(bounds, (self.horizontalPadding - 1.0), self.verticalPadding)); // -1.0 pixel workaround for NSAttributedString size bug
}

@end