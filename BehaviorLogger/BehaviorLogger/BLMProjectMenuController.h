//
//  BLMProjectMenuController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "BLMViewUtils.h"


extern NSString *const BLMCreateProjectCellText;
extern BLMColorHexCode const BLMCreateProjectCellTextColor;


#pragma mark

@interface BLMCreateProjectCell : UITableViewCell

@end


#pragma mark

@interface BLMProjectMenuController : UIViewController

- (void)loadProjectData;

@end
