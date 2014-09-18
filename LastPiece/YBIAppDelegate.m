//
//  YBIAppDelegate.m
//  LastPiece
//
//  Created by Alex Pojman on 7/29/14.
//  Copyright (c) 2014 Ya Boi Inc. All rights reserved.
//

#import "YBIAppDelegate.h"
#import "YBIViewController.h"
#import "Chameleon.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define paletteOrange 0xFFB13F
#define paletteYellow 0xFFDC50

@implementation YBIAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    YBIViewController *mainViewController = [[YBIViewController alloc] init];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mainViewController];

    
    // Place BNRItemsViewController's table view in the window hierarchy
    self.window.rootViewController = navController;
    
    // NavigationBar Customization
      
    // Remove bottom border from navBar
    [navController.navigationBar setShadowImage:[[UIImage alloc] init]];
    [navController.navigationBar setBackgroundImage:[[UIImage alloc]init] forBarMetrics:UIBarMetricsDefault];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
