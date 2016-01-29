//
//  BLMProjectMenuController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


extern NSString *const BLMProjectMenuControllerDidSelectProjectNotification;
extern NSString *const BLMProjectMenuControllerSelectedProjectUserInfoKey;


@interface BLMProjectMenuController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@end
