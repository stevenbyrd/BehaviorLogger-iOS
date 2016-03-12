//
//  BLMTextField.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/11/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


@class BLMTextField;


@protocol BLMTextFieldDelegate <UITextFieldDelegate>

- (NSIndexPath *)indexPathForCollectionViewCellTextField:(BLMTextField *)textField;

@end


#pragma mark

@interface BLMTextField : UITextField

@property (nonatomic, weak) id<BLMTextFieldDelegate> delegate;
@property (nonatomic, assign, readonly) CGFloat horizontalPadding;
@property (nonatomic, assign, readonly) CGFloat verticalPadding;

- (instancetype)initWithHorizontalPadding:(CGFloat)horizontalPadding verticalPadding:(CGFloat)verticalPadding;

@end
