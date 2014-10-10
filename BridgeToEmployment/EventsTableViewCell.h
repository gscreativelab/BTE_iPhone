//
//  EventsTableViewCell.h
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/5/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsTableViewCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *eventNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *eventDetailsLabel;
@property (nonatomic, strong) IBOutlet UIImageView *eventPhotoImageView;
@end
