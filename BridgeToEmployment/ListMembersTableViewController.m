//
//  ListMembersTableViewController.m
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/5/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "ListMembersTableViewController.h"
#import "ReachabilityUtil.h"
#import "CoreDataUtil.h"
#import "JNJEventDetTableViewController.h"
@interface ListMembersTableViewController ()
@property (nonatomic, strong) NSMutableArray *sections;
@end

static NSString *kScreenName = @"List Members";

@implementation ListMembersTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sections = [[NSMutableArray alloc] initWithCapacity:3];
    if(self.members.count > 0)
    {
        [self.sections addObject:@"Members"];
    }
    if(self.attendingMembers.count > 0)
    {
        [self.sections addObject:@"Attending"];
    }
    if(self.tentativeMembers.count > 0)
    {
        [self.sections addObject:@"Maybe"];
    }
    if(self.declinedMembers.count > 0)
    {
        [self.sections addObject:@"Declined"];
    }
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellList"];
    [self.tableView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tableviewBg.png"]]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAHelper trackScreenName:kScreenName];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section)
    {
        case 0:
        {
            if([[self.sections objectAtIndex:section] isEqualToString:@"Members"])
            {
                return self.members.count;
            }
            else if([[self.sections objectAtIndex:section] isEqualToString:@"Attending"])
            {
                return self.attendingMembers.count;
            }
        }
            break;
        case 1:
        {
            if([[self.sections objectAtIndex:section] isEqualToString:@"Maybe"])
            {
                return self.tentativeMembers.count;
            }
            else if([[self.sections objectAtIndex:section] isEqualToString:@"Declined"])
            {
                return self.declinedMembers.count;
            }
        }
            break;
        case 2:
        {
            return self.declinedMembers.count;
        }
            break;
            
        default:
            break;
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellList" forIndexPath:indexPath];
    switch (indexPath.section)
    {
        case 0:
        {
            if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Members"])
            {
                cell.textLabel.text = [[self.members objectAtIndex:indexPath.row] valueForKey:@"name"];
            }
            else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Attending"])
            {
                cell.textLabel.text = [[self.attendingMembers objectAtIndex:indexPath.row] valueForKey:@"name"];
            }
        }
            break;
        case 1:
        {
            if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Maybe"])
            {
                cell.textLabel.text = [[self.tentativeMembers objectAtIndex:indexPath.row] valueForKey:@"name"];
            }
            else if([[self.sections objectAtIndex:indexPath.section] isEqualToString:@"Declined"])
            {
                cell.textLabel.text = [[self.declinedMembers objectAtIndex:indexPath.row] valueForKey:@"name"];
            }
        }
            break;
        case 2:
        {
            cell.textLabel.text = [[self.declinedMembers objectAtIndex:indexPath.row] valueForKey:@"name"];
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
        {
            if(self.members.count > 0 || self.attendingMembers.count > 0)
            {
                return 35;
            }
        }
            break;
        case 1:
        case 2:
            return 35;
            break;
            
        default:
            break;
    }
    return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, 25.0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 5.0, self.tableView.bounds.size.width - 5.0, 25.0)];
    [headerView addSubview:label];
    
    switch (section)
    {
        case 0:
        {
            if(self.members.count > 0)
            {
                label.text = @"Members";
            }
            else if(self.attendingMembers.count > 0)
            {
                label.text = @"Attending";
            }
        }
            break;
        case 1:
        {
            if([[self.sections objectAtIndex:section] isEqualToString:@"Maybe"])
            {
                label.text = @"Tentative";
            }
            else if([[self.sections objectAtIndex:section] isEqualToString:@"Declined"])
            {
                label.text = @"Declined";
            }
            
        }
            break;
        case 2:
        {
            label.text = @"Declined";
        }
            break;
            
        default:
            break;
    }
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}


@end