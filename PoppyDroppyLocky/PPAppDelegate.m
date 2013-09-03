//
//  PPAppDelegate.m
//  PoppyDroppyLocky
//
//  Created by Joseph Gibson on 8/30/13.
//  Copyright (c) 2013 Joseph. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PPViewController.h"

@implementation PPAppDelegate
{
    PPViewController *rootController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    NSLog(@"bound width = %f", [[UIScreen mainScreen] bounds].size.width);
    NSLog(@"bound height = %f", [[UIScreen mainScreen] bounds].size.height);
    rootController = [[PPViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootController];
    
    [rootController setTitle:@"nom nom"];
    
    //UIToolbar *tools = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,90,55)];
    UIBarButtonItem *stillButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Button"
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(stillButtonPressed)];
    
    rootController.navigationItem.rightBarButtonItem = stillButton;
    
    [self.window setRootViewController:navController];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)stillButtonPressed
{
    [rootController setTitle:@"brains"];
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
