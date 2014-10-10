//
//  FullPostViewController.m
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/4/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "FullPostViewController.h"

@interface FullPostViewController ()
@end

@implementation FullPostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.postTextView.text = self.postString;
    [self.postTextView setFont:[UIFont fontWithName:@"Helvetica" size:15.0]];
}
@end
