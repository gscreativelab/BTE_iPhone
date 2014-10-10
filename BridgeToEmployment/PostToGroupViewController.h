//
//  PostToGroupViewController.h
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/5/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface PostToGroupViewController : GAITrackedViewController<UITextViewDelegate>
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UILabel *placeholderLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *postButton;
@property (nonatomic, strong) NSString *groupID;

- (IBAction)cancelButtonPressed;
- (IBAction)postButtonPressed;

@end
