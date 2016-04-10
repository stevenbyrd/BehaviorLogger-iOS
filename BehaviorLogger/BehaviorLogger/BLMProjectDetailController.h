//
//  BLMProjectDetailController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


@class BLMProjectDetailController;


@protocol BLMProjectDetailControllerDelegate <NSObject>

- (void)projectDetailControllerDidInitiateProjectCreation:(BLMProjectDetailController *)controller;

@end


#pragma mark

@interface BLMProjectDetailController : UIViewController

@property (nonatomic, strong, readonly) NSUUID *projectUUID;
@property (nonatomic, weak, readonly) id<BLMProjectDetailControllerDelegate> delegate;

- (instancetype)initWithProjectUUID:(NSUUID *)projectUUID delegate:(id<BLMProjectDetailControllerDelegate>)delegate;

@end


NS_ASSUME_NONNULL_END
