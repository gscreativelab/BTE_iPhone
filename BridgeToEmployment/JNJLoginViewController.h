//
//  JNJViewController.h
//  LoginView
//
//  Created by Kurt Prenger on 7/9/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <UIKit/UIKit.h>

// Facebook: The header that must be imported
#import <FacebookSDK/FacebookSDK.h>

// Facebook: The ViewController needs to conform to the FBLoginViewDelegate protocol to work properly
@interface JNJLoginViewController : GAITrackedViewController <FBLoginViewDelegate>

@property (weak, nonatomic) IBOutlet FBLoginView *fbButton;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (nonatomic, strong) NSString *userID;

@end
