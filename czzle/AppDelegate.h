//
//  AppDelegate.h
//  czzle
//
//  Created by Udo Von Eynern on 02.02.13.
//  Copyright (c) 2013 Udo Von Eynern / Alex Haslberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CocoaLibSpotify.h"
#import "MBProgressHUD.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@property (strong, nonatomic) MBProgressHUD *HUD;

- (void)showHUD;
- (void)hideHUD;

@end
