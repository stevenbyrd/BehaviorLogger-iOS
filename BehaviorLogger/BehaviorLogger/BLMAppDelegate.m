//
//  BLMAppDelegate.m
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import "BLMAppDelegate.h"
#import "BLMDataManager.h"
#import "BLMProjectMenuController.h"
#import "BLMProjectDetailController.h"


#pragma mark

@interface BLMAppDelegate () <UISplitViewControllerDelegate>

@property (nonatomic, strong, readonly) UISplitViewController *splitViewController;

@end


@implementation BLMAppDelegate

+ (instancetype)sharedInstance {
    return (BLMAppDelegate *)[UIApplication sharedApplication].delegate;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _splitViewController = [[UISplitViewController alloc] init];

    BLMProjectMenuController *projectMenuController = [[BLMProjectMenuController alloc] init];
    UINavigationController *primaryController = [[UINavigationController alloc] initWithRootViewController:projectMenuController];
    UINavigationController *detailController = [[UINavigationController alloc] init];
    
    self.splitViewController.viewControllers = @[primaryController, detailController];
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    self.splitViewController.preferredPrimaryColumnWidthFraction = 0.18;
    self.splitViewController.presentsWithGesture = NO;
    self.splitViewController.delegate = self;
    
    self.window.rootViewController = self.splitViewController;
    
    [self.window makeKeyAndVisible];

    [BLMDataManager initializeWithCompletion:^{
        [projectMenuController loadProjectData];
    }];
    
    return YES;
}

#pragma mark UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    NSLog(@"[%@ %@]> %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @(displayMode));
}


- (UIInterfaceOrientationMask)splitViewControllerSupportedInterfaceOrientations:(UISplitViewController *)splitViewController {
    return UIInterfaceOrientationMaskLandscape;
}


- (UIInterfaceOrientation)splitViewControllerPreferredInterfaceOrientationForPresentation:(UISplitViewController *)splitViewController {
    return UIInterfaceOrientationLandscapeLeft;
}

@end
