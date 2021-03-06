//
//  BLMCreateProjectController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 3/11/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


@class BLMCreateProjectController;
@class BLMProject;


@protocol BLMCreateProjectControllerDelegate <NSObject>

- (void)createProjectController:(BLMCreateProjectController *)controller didCreateProject:(BLMProject *)project;
- (void)createProjectController:(BLMCreateProjectController *)controller didFailWithError:(NSError *)error;
- (void)createProjectControllerDidCancel:(BLMCreateProjectController *)controller;

@end


#pragma mark

@interface BLMCreateProjectController : UIViewController

@property (nonatomic, weak, readonly) id<BLMCreateProjectControllerDelegate> delegate;

- (instancetype)initWithDelegate:(id<BLMCreateProjectControllerDelegate>)delegate;

@end


NS_ASSUME_NONNULL_END
