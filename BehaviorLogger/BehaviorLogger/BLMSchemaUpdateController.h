//
//  BLMEditSchemaController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class BLMProject;


@interface BLMSchemaUpdateController : UIViewController

@property (nonatomic, strong, readonly) BLMProject *project;

- (instancetype)initWithProject:(BLMProject *)project;

@end
