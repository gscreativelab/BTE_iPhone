//
//  GroupDetailsTableViewController.m
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/5/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "ListMembersTableViewController.h"
#import "GroupDetailsTableViewController.h"
#import "ReachabilityUtil.h"
#import "CoreDataUtil.h"
@interface GroupDetailsTableViewController ()
@property (nonatomic, strong) NSArray *groupMembers;
@end

static NSString *kScreenName = @"Group Details";

@implementation GroupDetailsTableViewController


#pragma mark -
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.groupMembers = [[NSArray alloc] init];
    [self getGroupMembers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAHelper trackScreenName:kScreenName];
}

#pragma mark - FB API Calls

- (void)getGroupMembers
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if(network)
    {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/members",self.groupID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                NSArray *resultData = [coreDataObj getValue:@"MemberDetails" eventId:nil];
                if(resultData != nil) // if data is available it deletes the existing value and inserts new data
                {
                    [coreDataObj deleteValue:@"MemberDetails" eventId:nil];
                }
                [coreDataObj saveValue:result attributeName:@"members" entityName:@"MemberDetails" eventId:nil];
                self.groupMembers = [result objectForKey:@"data"];
            }
            [self.tableView reloadData];
        }];
    }
    else //if there is no network gets data from DB
    {
        NSArray *resultData = [coreDataObj getValue:@"MemberDetails" eventId:nil];
        NSArray *arrData;
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"members"];
            }
            if(arrData != nil)
            {
                self.groupMembers = [arrData valueForKey:@"data"];
            }
            else
            {
                [coreDataObj showOfflineAlert];
            }
        }
        else
        {
            [coreDataObj showOfflineAlert];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return 10;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section)
    {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:@"membersIdentifier" forIndexPath:indexPath];
            cell.textLabel.text = [NSString stringWithFormat:@"%lu Members",(unsigned long)self.groupMembers.count];
            break;
        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:@"eventsCellIdentifier" forIndexPath:indexPath];
            break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"listGroupMembersSegue"])
    {
        ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
        BOOL network =  [reachNet checkNetworkStatus];
        CoreDataUtil *coreDataUtil = [CoreDataUtil sharedInstance];
        if(!network && self.groupMembers.count == 0)
        {
            [coreDataUtil showOfflineAlert];
        }
        else
        {
            ListMembersTableViewController *listMembersTableViewController = (ListMembersTableViewController*)segue.destinationViewController;
            listMembersTableViewController.members = self.groupMembers;
            listMembersTableViewController.title = @"Members";
        }
    }
}


@end
