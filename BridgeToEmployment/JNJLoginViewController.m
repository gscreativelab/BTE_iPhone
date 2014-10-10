//
//  JNJViewController.m
//  LoginView
//
//  Created by Kurt Prenger on 7/9/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//
//  Facebook login
//  - Documentation: https://developers.facebook.com/docs/ios/getting-started
//  - The FacebookSDK.framework is included in this project - see the Frameworks folder
//  - In the project's build settings, you'll need to add "-ObjC" as a linker flag
//  - There are two properties set in the project's -Info.plist file that Facebook uses
//  - This project is based on version 3.15.1
//  - The AppID in the .plist included in this project is a generic app created as a test, please modify it to match your app ID
//  - This project uses FBLoginView because you can have a bit more control over
//  - FB Login requires a few things within App Delegate - these are commented appropriately
//  - After login, the FBLoginView changes the button to say Logout
//

#import "JNJLoginViewController.h"
#import "JNJGroupsTableViewController.h"
#import "ReachabilityUtil.h"
#import "CoreDataUtil.h"
#import "JNJEventDetTableViewController.h"
@interface JNJLoginViewController ()

@end

static NSString *kScreenName = @"Login";

@implementation JNJLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.fbButton.readPermissions = @[@"public_profile", @"user_groups", @"publish_actions", @"user_events",@"rsvp_event",@"user_photos"];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    self.screenName = kScreenName;
}

#pragma mark - Login

// Facebook: method that is called after login to notify us to change UI
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    //Check for users current permissions
    NSArray *permissionsNeeded = @[@"public_profile", @"user_groups", @"publish_actions", @"user_events",@"rsvp_event",@"user_photos"];
    
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    if(network)
    {
        [FBRequestConnection startWithGraphPath:@"me/permissions"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                  if (!error){
                                      
                                      // These are the current permissions the user has:
                                      NSMutableArray *currentPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                                      
                                      for (NSDictionary *dict in (NSArray *)[result data]) {
                                          if([[dict valueForKey:@"status"] isEqualToString:@"granted"])
                                          {
                                              [currentPermissions addObject:dict[@"permission"]];
                                          }
                                      }
                                      
                                      // We will store here the missing permissions that we will have to request
                                      NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                                      
                                      // Check if all the permissions we need are present in the user's current permissions
                                      // If they are not present add them to the permissions to be requested
                                      for (NSString *permission in permissionsNeeded){
                                          if (![currentPermissions containsObject:permission]){
                                              [requestPermissions addObject:permission];
                                          }
                                      }
                                      
                                      // If we have permissions to request
                                      if ([requestPermissions count] > 0){
                                          // Ask for the missing permissions
                                          [FBSession.activeSession
                                           requestNewReadPermissions:requestPermissions
                                           completionHandler:^(FBSession *session, NSError *error) {
                                               if (!error) {
                                                   // Permission granted
                                                  // NSLog(@"new permissions %@", [FBSession.activeSession permissions]);
                                                   [self goToMain];
                                               } else {
                                                   // An error occurred, we need to handle the error
                                                   // See: https://developers.facebook.com/docs/ios/errors
                                               }
                                           }];
                                      } else {
                                          // Permissions are present, don't need to do anything
                                          [self goToMain];
                                      }
                                      
                                  } 
                              }];
    }
    else //during offline checks since the user has already logged in, home page is shown
    {
        [self goToMain];
    }
}

- (void)goToMain
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *mainView = [mainStoryboard instantiateInitialViewController];
    [self.view.window setRootViewController:mainView];
}

// Facebook: method that is called after logging out to notify us to change UI
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    self.userLabel.hidden = YES;
    self.joinButton.hidden = YES;
    self.joinButton.userInteractionEnabled = NO;
}

// Facebook: method that is called when the user successfully logs in and their info is fetched
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user
{
    self.userLabel.hidden = NO;
    self.userLabel.text = user.name;
    self.userID = user.objectID;
    JNJEventDetTableViewController *eventController = [[JNJEventDetTableViewController alloc]init];
    eventController.userID = user.objectID;
    NSLog(@"id %@",user.objectID);
}

// Facebook: method to handle possible errors that can occur during login
- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = kFacebookError;
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures that happen outside of the app
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = kSessionError;
        alertMessage = kLogin;
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"%@",kUserCancel);
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:kCancel
                          otherButtonTitles:nil] show];
    }
}
@end
