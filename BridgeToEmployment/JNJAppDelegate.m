//
//  JNJAppDelegate.m
//  LoginView
//
//  Created by Kurt Prenger on 7/9/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "JNJAppDelegate.h"


// Facebook: The headers that must be imported
#import <FacebookSDK/FacebookSDK.h>

@implementation JNJAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    [[GAI sharedInstance] trackerWithTrackingId:@"GA ID here"];
    return YES;
}

// Facebook: This needs to be overridden for the Facebook Login
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // Facebook: Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL FBwasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    // returns TRUE if either FB or Google was the URL scheme being called
    return FBwasHandled;
}



@end
