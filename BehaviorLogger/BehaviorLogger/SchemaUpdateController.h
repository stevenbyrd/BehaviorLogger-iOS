//
//  EditSchemaController.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/7/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class Project;


@interface SchemaUpdateController : UIViewController

@property (nonatomic, strong, readonly) Project *project;

- (instancetype)initWithProject:(Project *)project;

@end
