//
//  JNJEventDetTableViewController.h
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/5/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <MessageUI/MessageUI.h>

@interface JNJEventDetTableViewController : UITableViewController<UIActionSheetDelegate,MFMailComposeViewControllerDelegate>
@property (nonatomic, strong) NSString *eventID;
@property (nonatomic) BOOL isPastEvent;
@property (nonatomic) BOOL isListMembers;
@property (strong, nonatomic) NSString *organizerID;
@property (retain) NSString *userID;
@end
