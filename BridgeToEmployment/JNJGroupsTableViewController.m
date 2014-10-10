//
//  JNJGroupsTableViewController.m
//  BridgeToEmployment
//
//  Created by Kurt Prenger on 8/3/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "GroupDetailsTableViewController.h"
#import "GroupsPhotoTableViewCell.h"
#import "RecentPostTableViewCell.h"
#import "FullPostViewController.h"
#import "PostToGroupViewController.h"
#import "JNJGroupsTableViewController.h"
#import "CoreDataUtil.h"
#import "ReachabilityUtil.h"
#include "ImageUtils.h"

@interface JNJGroupsTableViewController ()

@property (nonatomic) BOOL foundGroup;

@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSString *groupID;
@property (nonatomic, strong) UIImage *groupImage;
@property (nonatomic, strong) NSMutableArray *recentPostsArray;

@end

static NSString *kScreenName = @"Groups";

@implementation JNJGroupsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.recentPostsArray = [[NSMutableArray alloc] init];
    self.foundGroup = NO;
    self.groupName = @"Bridge To Employment";
    self.title = self.groupName;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [GAHelper trackScreenName:kScreenName];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [self getUserGroups];
}

#pragma mark - Joining group
- (void)joinButtonTouched:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/505668282896958/"]];
}

#pragma mark - Getting group info

//Gets the group cover photo and saves it in a file named as groupCoverPhoto
- (void)getGroupImage:(NSString*)groupID
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    ImageUtils *imgUtils = [[ImageUtils alloc]init];
    if(network)
    {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@?fields=cover",groupID] parameters:nil HTTPMethod:@"GET" completionHandler:^(                                                                     FBRequestConnection *connection, id result, NSError *error)
         {
             if (!error)
             {
                 __block NSURL *url;
                 if([result valueForKey:@"cover"] )
                 {
                     url = [NSURL URLWithString:[[result valueForKey:@"cover"] valueForKey:@"source"]];
                     NSData *data = [NSData dataWithContentsOfURL:url];
                     UIImage *img = [[UIImage alloc] initWithData:data];
                     [imgUtils saveImage:img fileName:@"groupCoverPhoto.png"];
                     self.groupImage = img;
                     [self.tableView reloadData];
                 }
                 else
                 {
                     [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@?fields=picture.type(large)",groupID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                         if (!error)
                         {
                             url = [NSURL URLWithString:[[[result valueForKey:@"picture"] valueForKey:@"data"] valueForKeyPath:@"url"]];
                             NSData *data = [NSData dataWithContentsOfURL:url];
                             UIImage *img = [[UIImage alloc] initWithData:data];
                             [imgUtils saveImage:img fileName:@"groupCoverPhoto.png"];
                             self.groupImage = img;
                             [self.tableView reloadData];
                         }
                     }];
                 }
             }
         }];
    }
    else //when there is no network image is fetched from saved file
    {
        UIImage *img = [imgUtils loadImage:@"groupCoverPhoto.png"];
        self.groupImage = img;
        [self.tableView reloadData];
    }
}


- (void)getRecentFeeds:(NSString*)groupID
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if (network) {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/feed",self.groupID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                NSArray *resultData =nil;
                resultData = [coreDataObj getValue:@"RecentFeeds" eventId:nil];
                if(resultData != nil)//delete and insert data into DB
                {
                    [coreDataObj deleteValue:@"RecentFeeds" eventId:nil];
                }
                [coreDataObj saveValue:result attributeName:@"response" entityName:@"RecentFeeds" eventId:nil];
                [self setRecentFeedsData:result];
            }
       }];
    }
    else //if no network, call from DB
    {
        NSArray *resltFeed = [coreDataObj getValue:@"RecentFeeds" eventId:nil];
        NSString *arrData;
        if(resltFeed != nil)
        {
            for (NSManagedObject *info in resltFeed) {
                arrData = [info valueForKey:@"response"];
            }
            [self setRecentFeedsData:arrData];
        }
        else
        {
            [coreDataObj showOfflineAlert];
        }
    }
    [self.tableView reloadData];
}

-(void)setRecentFeedsData:(id)result
{
    NSArray *recentPosts = [result objectForKey:@"data"];
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    //grab top 5 posts made in the group
    for(NSInteger i = 0; i < [recentPosts count]; i++)
    {
        if(tempArray.count < 5)
        {
            if([[[recentPosts objectAtIndex:i] valueForKeyPath:@"type"] isEqualToString:@"status"] && [[recentPosts objectAtIndex:i] valueForKeyPath:@"message"])
            {
                [tempArray addObject:[recentPosts objectAtIndex:i]];
            }
        }
    }
    self.recentPostsArray = tempArray;
    [self.tableView reloadData];
}

//Get the user's current groups
//GroupMembers entity is used to store groups details and retrieved from it in case of no network
- (void)getUserGroups
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if (network) {
        [FBRequestConnection startWithGraphPath:@"me/groups" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                NSArray *resultData = [coreDataObj getValue:@"GroupMembers" eventId:nil];
                if(resultData != nil)
                {
                    [coreDataObj deleteValue:@"GroupMembers" eventId:nil];
                }
                [coreDataObj saveValue:result attributeName:@"groupMembers" entityName:@"GroupMembers" eventId:nil];
            }
            [self setUserGroupsData:result];
        }];
    }
    else
    {
        NSArray *resultData = [coreDataObj getValue:@"GroupMembers" eventId:nil];
        NSString *arrData;
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"groupMembers"];
            }
            [self setUserGroupsData:arrData];
        }
    }
    [self.tableView reloadData];
}

-(void)setUserGroupsData:(id)resultJSON
{
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
    NSString *targetID = [data objectForKey:@"FacebookGroupID"];
    
    NSArray *groupArray = [resultJSON objectForKey:@"data"];
    for (id group in groupArray) {
        self.groupID = [group objectForKey:@"id"];
        if ([self.groupID isEqualToString:targetID])
        {
            self.foundGroup = YES;
            self.groupName = [group objectForKey:@"name"];
            [self getRecentFeeds:self.groupID];
            [self getGroupImage:self.groupID];
            break;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //first three section are the group image, the group name and ability for user to post to group
    if(self.foundGroup)
    {
        return 2 + self.recentPostsArray.count;
    }
    else
    {
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

#pragma mark - Logout
- (void)logOutUser
{
    [FBSession.activeSession closeAndClearTokenInformation];
    [self goToLogin];
}

- (void)goToLogin
{
    UIStoryboard *loginStoryboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    UIViewController *mainView = [loginStoryboard instantiateInitialViewController];
    [self.view.window setRootViewController:mainView];
}

#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if(indexPath.section == 0)
    {
        GroupsPhotoTableViewCell *cell = (GroupsPhotoTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"groupPhotoCellIdentifier"];
        
        if(self.foundGroup)
        {
            cell.groupPhotoImageView.image = self.groupImage;
        }
        else
        {
            cell.groupPhotoImageView.image = [UIImage imageNamed:@"bte"];
        }
        return cell;
    }
    
    else if(indexPath.section == 1)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"groupNameCellIdentifier"];
        cell.textLabel.text = self.groupName;
        if(!self.foundGroup)
        {
            cell.userInteractionEnabled = NO;
        }
        else
        {
            cell.userInteractionEnabled = YES;
        }
    }
    else if (self.foundGroup)
    {
        if(self.recentPostsArray.count > 0)
        {
            RecentPostTableViewCell *cell = (RecentPostTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"groupTextCellIdentifier"];
            cell.postLabel.text = [[self.recentPostsArray objectAtIndex:(indexPath.section - 2)] valueForKey:@"message"];
            cell.authorLabel.text = [[[self.recentPostsArray objectAtIndex:(indexPath.section - 2)] valueForKey:@"from"] valueForKey:@"name"];
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            NSDate *date;
            
            [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
            date = [dateFormat dateFromString:[[self.recentPostsArray objectAtIndex:(indexPath.section - 2)] valueForKey:@"created_time"]];
            [dateFormat setDateFormat:@"MMM dd"];
            cell.dateTimeLabel.text = [dateFormat stringFromDate:date];
            
            CGSize size = [cell.postLabel.text sizeWithAttributes:@{NSFontAttributeName:cell.postLabel.font}];
            if (size.width < cell.postLabel.bounds.size.width)
            {
                cell.showMoreButton.hidden = YES;
            }
            else
            {
                cell.showMoreButton.hidden = NO;
            }
            return cell;
        }
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"joinGroupCellIdentifier"];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(section != 1)
    {
        if(section == 0 && !self.foundGroup)
        {
            return 1;
        }
        return CGFLOAT_MIN;
    }
    
    return 0.5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section > 1)
    {
        if(section == 2)
        {
            return 40.0;
        }
        return 10.0;
    }
    
    return CGFLOAT_MIN;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 10.0, tableView.bounds.size.width, 25.0)];
    if(section == 2)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 10.0, tableView.bounds.size.width, 25.0)];
        label.text = @"Announcements";
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        
        [headerView addSubview:label];
    }
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return 200;
    }
    else if(indexPath.section == 1)
    {
        return 34;
    }
    else if(self.recentPostsArray.count > 0 && self.foundGroup)
    {
        RecentPostTableViewCell *cell = (RecentPostTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"groupTextCellIdentifier"];
        cell.postLabel.text = [[self.recentPostsArray objectAtIndex:(indexPath.section - 2)] valueForKey:@"message"];
        
        if(cell.postLabel.text.length > 0)
        {
            CGSize size = [cell.postLabel.text sizeWithAttributes:@{NSFontAttributeName:cell.postLabel.font}];
            if (size.width < cell.postLabel.bounds.size.width)
            {
                return 100;
            }
            else
            {
                return 120;
            }
        }
    }
    
    return 50;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:@"joinGroupCellIdentifier"])
    {
        [self joinButtonTouched:nil];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    if([segue.identifier isEqualToString:@"showFullPostSegueIdentifier"])
    {
        FullPostViewController *fullPostViewController = (FullPostViewController*)segue.destinationViewController;
        RecentPostTableViewCell *recentPostCell = (RecentPostTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        fullPostViewController.postString = recentPostCell.postLabel.text;;
        fullPostViewController.title = recentPostCell.authorLabel.text;
    }
    else if([segue.identifier isEqualToString:@"groupInfoSegueIdentifier"])
    {
        
        GroupDetailsTableViewController *groupDetailsViewController = (GroupDetailsTableViewController*)segue.destinationViewController;
        groupDetailsViewController.groupID = self.groupID;
        groupDetailsViewController.title = self.groupName;
    }
}

@end
