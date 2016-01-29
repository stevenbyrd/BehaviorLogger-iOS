//
//  BLMProjectDetailController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class BLMProject;


@interface BLMProjectDetailController : UIViewController

@property (nonatomic, strong, readonly) NSNumber *projectUid;

- (instancetype)initWithProject:(BLMProject *)project;

@end
