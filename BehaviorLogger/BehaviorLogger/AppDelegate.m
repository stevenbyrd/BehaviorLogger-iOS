//
//  AppDelegate.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "AppDelegate.h"
#import "ProjectMenuController.h"
#import "ProjectDetailController.h"


@implementation AppDelegate

+ (instancetype)sharedInstance {
    return [UIApplication sharedApplication].delegate;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _splitViewController = [[UISplitViewController alloc] init];
    
    UINavigationController *primaryController = [[UINavigationController alloc] initWithRootViewController:[[ProjectMenuController alloc] init]];
    UINavigationController *detailController = [[UINavigationController alloc] initWithRootViewController:[[ProjectDetailController alloc] init]];
    
    self.splitViewController.viewControllers = @[primaryController, detailController];
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    self.splitViewController.preferredPrimaryColumnWidthFraction = 0.25;
    self.splitViewController.presentsWithGesture = NO;
    
    self.window.rootViewController = self.splitViewController;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
