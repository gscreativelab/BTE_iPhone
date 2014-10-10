//
//  ListMembersTableViewController.h
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/5/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListMembersTableViewController : UITableViewController
@property (nonatomic, strong) NSArray *members;
@property (nonatomic, strong) NSArray *attendingMembers;
@property (nonatomic, strong) NSArray *tentativeMembers;
@property (nonatomic, strong) NSArray *declinedMembers;
@property (nonatomic,strong) NSString *eventID;
@end
