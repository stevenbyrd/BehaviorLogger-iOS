//
//  BLMTextField.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/11/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


@class BLMTextField;


@protocol BLMTextFieldDelegate <UITextFieldDelegate>

- (NSIndexPath *)indexPathForCollectionViewCellTextField:(BLMTextField *)textField;

@end


#pragma mark

@interface BLMTextField : UITextField

@property (nullable, nonatomic, weak) id<BLMTextFieldDelegate> delegate;
@property (nonatomic, assign, readonly) CGFloat horizontalPadding;
@property (nonatomic, assign, readonly) CGFloat verticalPadding;

- (instancetype)initWithHorizontalPadding:(CGFloat)horizontalPadding verticalPadding:(CGFloat)verticalPadding;

@end


NS_ASSUME_NONNULL_END
