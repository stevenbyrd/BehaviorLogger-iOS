//
//  ProjectMenuController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


extern NSString *const ProjectMenuControllerDidSelectProjectNotification;
extern NSString *const ProjectMenuControllerSelectedProjectUserInfoKey;


@interface ProjectCell : UITableViewCell

@end


@interface CreateProjectCell : UITableViewCell

@property (nonatomic, strong, readonly) UIView *separatorView;

@end


@interface ProjectMenuController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@end
