//
//  RecentPostTableViewCell.h
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/4/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecentPostTableViewCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *authorLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateTimeLabel;
@property (nonatomic, strong) IBOutlet UILabel *postLabel;
@property (nonatomic, strong) IBOutlet UIButton *showMoreButton;
@end
