//
//  AppDelegate.m
//  czzle
//
//  Created by Udo Von Eynern on 02.02.13.
//  Copyright (c) 2013 Udo Von Eynern / Alex Haslberger. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

@implementation AppDelegate

@synthesize HUD;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)showHUD {
    if (HUD == nil) {
        HUD = [[MBProgressHUD alloc] initWithWindow:self.window];
        HUD.detailsLabelText = @"Please be patient...";
    }
    [self.window addSubview:HUD];
    [HUD show:YES];
}

- (void)hideHUD {
    if (HUD) {
        [HUD hide:YES];
    }
    
}

@end
