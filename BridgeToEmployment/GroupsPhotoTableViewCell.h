//
//  GroupsPhotoTableViewCell.h
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/4/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupsPhotoTableViewCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UIImageView *groupPhotoImageView;
@property (nonatomic, strong) IBOutlet UILabel *eventTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *eventOrganizerLabel;
@property (nonatomic, strong) IBOutlet UILabel *groupNameLabel;
@end
