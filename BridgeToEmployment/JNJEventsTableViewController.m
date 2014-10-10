//
//  JNJEventsTableViewController.m
//  BridgeToEmployment
//
//  Created by Kurt Prenger on 8/1/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "EventsTableViewCell.h"
#import "JNJEventsTableViewController.h"
#import "JNJEventDetTableViewController.h"
#import "CoreDataUtil.h"
#import "ReachabilityUtil.h"
#import "ImageUtils.h"

@interface JNJEventsTableViewController ()

@property (strong, nonatomic) NSString *groupID;
@property (strong, nonatomic) NSArray *eventArray;
@property (strong, nonatomic) NSMutableDictionary *eventImageDictionary;
@end

static NSString *kScreenName = @"Events";

@implementation JNJEventsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.eventArray = [[NSArray alloc] init];
    self.eventImageDictionary = [[NSMutableDictionary alloc] init];
    
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
    self.groupID = [data objectForKey:@"FacebookGroupID"];
    [self getGroupEvents];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAHelper trackScreenName:kScreenName];
}

#pragma mark - FB API calls

- (void) getEventImages:(NSString*)eventID;
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [[CoreDataUtil alloc]init];
    if(network){
        NSString *graphPath = [NSString stringWithFormat:@"%@?fields=picture.type(large)",eventID];
        [FBRequestConnection startWithGraphPath:graphPath completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                [self.eventImageDictionary setObject:result forKey:eventID];
                [self.tableView reloadData];
                NSArray *resultData = [coreDataObj getValue:@"EventImageDetails" eventId:nil];
                if(resultData != nil) //deletes data if available and inserts
                {
                    [coreDataObj deleteValue:@"EventImageDetails" eventId:nil];
                }
                [coreDataObj saveValue:result attributeName:@"imageDetails" entityName:@"EventImageDetails" eventId:nil];
            }
        }];
    }
    else //if network is not available result is fetched from DB
    {
        NSArray *resultData = [coreDataObj getValue:@"EventImageDetails" eventId:nil];
        NSString *arrData;
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"imageDetails"];
            }
            if(arrData != nil)
            {
                [self.eventImageDictionary setObject:arrData forKey:eventID];
                [self.tableView reloadData];
            }
        }
    }
}


#pragma mark - Table view data source/delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.eventArray.count;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EventsTableViewCell *cell = (EventsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"eventDetailsCellIdentifier" forIndexPath:indexPath];
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    ImageUtils *imgUtils = [[ImageUtils alloc]init];
    NSString *idToSave;
    idToSave =[[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"id"];
    cell.eventNameLabel.text = [[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"name"];
    if (network) {
        NSURL *url =  [NSURL URLWithString:[[[[self.eventImageDictionary objectForKey:[[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"id"]] valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"]];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *img = [[UIImage alloc] initWithData:data];
        cell.eventPhotoImageView.image = img;
        if (idToSave != nil) {
            [imgUtils saveImage:img fileName:[NSString stringWithFormat:@"%@.png",idToSave]];
        }
    }
    else
    {
        if (idToSave != nil) {
            UIImage *img = [imgUtils loadImage:[NSString stringWithFormat:@"%@.png",idToSave]];
            cell.eventPhotoImageView.image = img;
        }
    }
    NSString *dateString = [[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"start_time"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    NSDate *date;
    
    //Date time is returned in two different formats depending on if a start time has been specified or not
    if([[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"timezone"] && !([dateString rangeOfString:@":"].location == NSNotFound)) //when time is specified
    {
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
        date = [dateFormat dateFromString:dateString];
        [dateFormat setDateFormat:@"eee MMM dd, yyyy hh:mm"];
        cell.eventDetailsLabel.text = [dateFormat stringFromDate:date];
    }
    else
    {
        [dateFormat setDateFormat:@"yyyy-MM-dd"];
        date = [dateFormat dateFromString:dateString];
        [dateFormat setDateFormat:@"eee MMM dd, yyyy"];
        cell.eventDetailsLabel.text = [dateFormat stringFromDate:date];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

#pragma mark - Get FB group info

- (void)getGroupEvents
{
    NSString *graphPath = [NSString stringWithFormat:@"%@/events", self.groupID];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:[[NSDate alloc] init]];
    
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    
    [components setHour:-24];
    [components setMinute:0];
    [components setSecond:0];
    
    components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[[NSDate alloc] init]];
    
    [components setDay:([components day] - 14)];
    NSDate *twoWeeksFromToday = [cal dateFromComponents:components];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:twoWeeksFromToday];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            formattedDateString, @"since",nil];
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [[CoreDataUtil alloc]init];
    if (network) {
        [FBRequestConnection startWithGraphPath:graphPath parameters:params HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                NSArray *resultData = [coreDataObj getValue:@"GroupEvents" eventId:nil];
                if(resultData != nil)//delete and insert if exist
                {
                    [coreDataObj deleteValue:@"GroupEvents" eventId:nil];
                }
                [coreDataObj saveValue:result attributeName:@"events" entityName:@"GroupEvents" eventId:nil];
                self.eventArray = [result objectForKey:@"data"];
                for (id eventID in self.eventArray) {
                    [self getEventImages:[eventID objectForKey:@"id"]];
                }
                [self.tableView reloadData];
            }
        }];
    }
    else // when no network get result from DB
    {
        NSArray *resultData = [coreDataObj getValue:@"GroupEvents" eventId:nil];
        NSString *arrData;
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"events"];
            }
            if(arrData != nil)
            {
                self.eventArray = [arrData valueForKey:@"data"];
                for (id eventID in self.eventArray) {
                    [self getEventImages:[eventID objectForKey:@"id"]];
                }
                [self.tableView reloadData];
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"eventDetailSegueIdentifier"])
    {
        JNJEventDetTableViewController *eventDetailsTableViewControllerersTableViewController = (JNJEventDetTableViewController*)segue.destinationViewController;
        EventsTableViewCell *cell = (EventsTableViewCell*)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        eventDetailsTableViewControllerersTableViewController.title = [[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"name"];
        eventDetailsTableViewControllerersTableViewController.eventID = [[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"id"];
        
        //check is the event has occurred or not
        NSDate *currentDate = [NSDate date];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        NSDate *date;
        NSString *dateString = [[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"start_time"];
        
        if([[self.eventArray objectAtIndex:indexPath.section] valueForKey:@"timezone"] && !([dateString rangeOfString:@":"].location == NSNotFound)) //when time is not specified in start time
        {
            currentDate = [NSDate date];
            [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
            date = [dateFormat dateFromString:dateString];
            [dateFormat setDateFormat:@"yyyy-MM-dd"];
            dateString = [dateFormat stringFromDate:date];
            date = [dateFormat dateFromString:dateString];
        }
        else
        {
            [dateFormat setDateFormat:@"yyyy-MM-dd"];
            date = [dateFormat dateFromString:dateString];
            NSDate *currDate = [NSDate date];
            NSString *dateStr = [dateFormat stringFromDate:currDate];
            currentDate = [dateFormat dateFromString:dateStr];
        }
        
        NSComparisonResult result = [currentDate compare:date];
        if(result == NSOrderedDescending)
        {
            eventDetailsTableViewControllerersTableViewController.isPastEvent = YES;
        }
    }
}

@end
