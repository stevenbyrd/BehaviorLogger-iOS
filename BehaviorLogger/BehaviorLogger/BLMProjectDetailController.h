//
//  BLMProjectDetailController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, BLMProjectDetailSection) {
    BLMProjectDetailSectionBasicInfo,
    BLMProjectDetailSectionSessionProperties,
    BLMProjectDetailSectionBehaviors,
    BLMProjectDetailSectionActionButtons,
    BLMProjectDetailSectionCount
};


@class BLMProject;


@interface BLMProjectDetailController : UIViewController

@property (nonatomic, strong, readonly) NSUUID *projectUUID;

- (instancetype)initWithProject:(BLMProject *)project;

@end
