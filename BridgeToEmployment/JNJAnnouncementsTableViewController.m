//
//  JNJAnnouncementsTableViewController.m
//  BridgeToEmployment
//
//  Created by Kurt Prenger on 8/1/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "JNJAnnouncementsTableViewController.h"

@interface JNJAnnouncementsTableViewController ()

@property (weak, nonatomic) IBOutlet UITableView *announcementTableView;
@property (strong, nonatomic) NSString *groupID;
@property (strong, nonatomic) NSArray *announcementArray;

@end

@implementation JNJAnnouncementsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.announcementArray = @[@"Loading announcements..."];
    
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
    self.groupID = [data objectForKey:@"FacebookGroupID"];
    [self getGroupAnnouncements];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.announcementArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"announcementCell" forIndexPath:indexPath];
    cell.textLabel.text = self.announcementArray[indexPath.row];
    
    return cell;
}

#pragma mark - Get FB group info

- (void)getGroupAnnouncements
{
    NSString *graphPath = [NSString stringWithFormat:@"%@/feed", self.groupID];
    [FBRequestConnection startWithGraphPath:graphPath completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error)
        {
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            
            NSArray *feedArray = [result objectForKey:@"data"];
            for (id announcement in feedArray) {
                NSString *message = [announcement objectForKey:@"message"];
                NSString *owner = [[announcement objectForKey:@"from"] objectForKey:@"name"];
                [tempArray addObject:[NSString stringWithFormat:@"%@ by %@", message, owner]];
            }
            
            self.announcementArray = tempArray;
            [self.announcementTableView reloadData];
        }
       
    }];
}

@end
