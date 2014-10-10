//
//  PostToGroupViewController.m
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/5/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "CoreDataUtil.h"
#import "PostToGroupViewController.h"
#import "ReachabilityUtil.h"

@interface PostToGroupViewController ()
@property (nonatomic, strong) NSString *postString;
@end

static NSString *kScreenName = @"Post to Group";

@implementation PostToGroupViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.screenName = kScreenName;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textView.delegate = self;
    self.postButton.enabled = NO;
    // Do any additional setup after loading the view.
}

#pragma mark - Posting

- (void)cancelButtonPressed
{
    [self.textView resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)postButtonPressed
{
    [self.textView resignFirstResponder];
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    if(network){
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.postString, @"message",
                                nil
                                ];
        /* make the API call */
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/feed",self.groupID]
                                     parameters:params
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection,id result,NSError *error)
         {
             if(!error)
             {
                 NSLog(@"POSTED");
             }
             else
             {
                 if([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryPermissions)
                 {
                     UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:kNetworkStatus message:kUserDenied delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil, nil];
                     [alertView show];
                 }
             }
         }];
    }
    else//alert is thrown to check for net connection if there is no network
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:kNetworkStatus message:kOfflinePost delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if(textView.text.length > 0)
    {
        self.postButton.enabled = YES;
        self.placeholderLabel.hidden = YES;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.postButton.enabled = NO;
        self.placeholderLabel.hidden = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    self.postString = textView.text;
}

@end
