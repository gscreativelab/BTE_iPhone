//
//  JNJEventDetTableViewController.m
//  BridgeToEmployment
//
//  Created by Vania Nettleford on 8/5/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "EventsTableViewCell.h"
#import "GroupsPhotoTableViewCell.h"
#import "JNJEventDetTableViewController.h"
#import "ListMembersTableViewController.h"
#import "RecentPostTableViewCell.h"
#import "FullPostViewController.h"
#import "PostToGroupViewController.h"
#import "CoreDataUtil.h"
#import "ReachabilityUtil.h"
#import "JNJGroupsTableViewController.h"
#import "ImageUtils.h"
#import "JNJLoginViewController.h"

@interface JNJEventDetTableViewController ()
@property (nonatomic, strong) NSDictionary *eventDetailDictionary;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSArray *attendeesArray;
@property (nonatomic, strong) NSArray *tentativesArray;
@property (nonatomic, strong) NSArray *declinedArray;
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *RSVPStatus;
@property (nonatomic, strong) UIImage *eventImage;
@property (nonatomic, strong) NSArray *recentPostsArray;
@property (nonatomic) BOOL isPastAndAttend;
@end

static NSString *kScreenName = @"Event Details";

@implementation JNJEventDetTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isPastAndAttend = NO;
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
    self.groupName = [data objectForKey:@"FacebookDisplayName"];
    [self getEventDetails];
    [self getEventImage];
    [self getRSVPStatus];
    
    NSString *detailedScreenName = [NSString stringWithFormat:@"%@: %@", kScreenName, self.groupName];
    [GAHelper trackScreenName:detailedScreenName];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self getEventPosts];
}

-(void)viewWillAppear:(BOOL)animated{
    [self.tableView setUserInteractionEnabled:YES];
}

#pragma mark - FB API Calls

//Offline feature is added
- (void)getEventPosts
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if(network){
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/feed",self.eventID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                //gets data from EVentPosts entity
                //if data is available deletes the existing one and inserts new value
                NSArray *resultData = [coreDataObj getValue:@"EventPosts" eventId:self.eventID];
                if(resultData != nil)
                {
                    [coreDataObj deleteValue:@"EventPosts" eventId:self.eventID];
                }
                [coreDataObj saveValue:result attributeName:@"eventPosts" entityName:@"EventPosts" eventId:self.eventID];
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
        }];
    }
    else //In case there is no network, data is fetched from EventPosts entity and shown
    {
        NSArray *resultData = [coreDataObj getValue:@"EventPosts" eventId:self.eventID];
        NSString *arrData;
        
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"eventPosts"];
            }
            if(arrData != nil)
            {
                [self setEventPosts:arrData];
            }
        }
    }
}
-(void)setEventPosts:(id)result
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

- (void)getEventImage
{
    ImageUtils *imgUtils = [[ImageUtils alloc]init];
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    if(network){
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@?fields=picture.type(large)",self.eventID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                NSURL *url = [NSURL URLWithString:[[[result valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"]];
                NSData *data = [NSData dataWithContentsOfURL:url];
                UIImage *img = [[UIImage alloc] initWithData:data];
                self.eventImage = img;
                [self.tableView reloadData];
                // saves the image from the url in a file with its event id as name for that file
                [imgUtils saveImage:self.eventImage fileName:[NSString stringWithFormat:@"%@.png",self.eventID]];
            }
        }];
    }
    else //if there is no network, image is loaded from the file saved
    {
        UIImage *img = [imgUtils loadImage:[NSString stringWithFormat:@"%@.png",self.eventID]];
        self.eventImage = img;
        [self.tableView reloadData];
    }
}

- (void)getRSVPStatus
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if(network){
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/me"] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                self.id = [result valueForKey:@"id"];
                [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/invited/%@",self.eventID, self.id] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (! error)
                    {
                        NSArray *resultData = [coreDataObj getValue:@"RSVPStatus" eventId:self.eventID];
                        //checks for RSVP status in local db, if available deletes the old one and inserts fresh value
                        if(resultData != nil)
                        {
                            [coreDataObj deleteValue:@"RSVPStatus" eventId:self.eventID];
                        }
                        [coreDataObj saveValue:result attributeName:@"status" entityName:@"RSVPStatus" eventId:self.eventID];
                        if([[result valueForKey:@"data"] count] > 0)
                        {
                            self.RSVPStatus = [[[result valueForKey:@"data"] valueForKey:@"rsvp_status"] objectAtIndex:0];
                        }
                        else
                        {
                            self.RSVPStatus = @"not_replied";
                        }
                        
                        [self.tableView reloadData];
                    }
                }];
            }
        }];
    }
    else // if there is no network, RSVP status is fetched from local db and populated in UI
    {
        NSArray *resultData = [coreDataObj getValue:@"RSVPStatus" eventId:self.eventID];
        NSString *arrData;
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"status"];
            }
            if(arrData != nil && [[arrData valueForKey:@"data"] count]>0)
            {
                self.RSVPStatus = [[[arrData valueForKey:@"data"] valueForKey:@"rsvp_status"] objectAtIndex:0];
                [self.tableView reloadData];
            }
            else{
                self.RSVPStatus = @"not_replied";
            }
        }
    }
}


- (void)getEventDetails
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus]; //checks for net connection
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if(network){
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/",self.eventID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                //Event Details entity is checked for value. If exists, it is replaced with new data
                NSArray *resultData = [coreDataObj getValue:@"EventDetails" eventId:self.eventID];
                if(resultData != nil)
                {
                    [coreDataObj deleteValue:@"EventDetails" eventId:self.eventID];
                }
                [coreDataObj saveValue:result attributeName:@"eventDetails" entityName:@"EventDetails" eventId:self.eventID];
                self.eventDetailDictionary = result;
                [self.tableView reloadData];
            }
        }];
    }
    else //Data from local db is retrieved and populated
    {
        NSArray *resultData = [coreDataObj getValue:@"EventDetails" eventId:self.eventID];
        NSDictionary *arrData;
        
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"eventDetails"];
            }
            if(arrData != nil)
            {
                self.eventDetailDictionary = arrData;
                [self.tableView reloadData];
            }
            else{
                [coreDataObj showOfflineAlert];
            }
        }
        else
        {
            [coreDataObj showOfflineAlert];
        }
    }
}

- (void)getEventAttendees
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if (network) {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/attending",self.eventID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                //EventAttendees values are checked in local DB. If available it is deleted and inserted with the new copy
                NSArray *resultData = [coreDataObj getValue:@"EventAttendees" eventId:self.eventID];
                if(resultData != nil)
                {
                    [coreDataObj deleteValue:@"EventAttendees" eventId:self.eventID];
                }
                [coreDataObj saveValue:result attributeName:@"eventAttendees" entityName:@"EventAttendees" eventId:self.eventID];
                self.attendeesArray = [result valueForKey:@"data"];
                [self showMembersList];
            }
        }];
    }
    else //Attendees are fetched from EventAttendees entity if available and shown to user
    {
        NSArray *resultData = [coreDataObj getValue:@"EventAttendees" eventId:self.eventID];
        NSString *arrData;
        
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"eventAttendees"];
            }
            if(arrData != nil) //If value is there ListMembersTableViewController view is initialized, check for internet connection alert is thrown
            {
                self.attendeesArray = [arrData valueForKey:@"data"];
                [self showMembersList];
            }
        }
        if(self.attendeesArray.count == 0 && self.tentativesArray.count == 0 && self.declinedArray.count ==0)
        {
            [coreDataObj showOfflineAlert];
            [self.tableView setUserInteractionEnabled:YES];
        }
    }
}

/**
 * To initialize ListMembersTableViewController view
 * @return void
 */
-(void)showMembersList
{
    ListMembersTableViewController *listController = [[ListMembersTableViewController alloc]init];
    listController.attendingMembers = self.attendeesArray;
    listController.tentativeMembers = self.tentativesArray;
    listController.declinedMembers = self.declinedArray;
    listController.title = @"Attendees";
    [listController.tableView reloadData];
    [self.navigationController pushViewController:listController animated:YES];
}

- (void)getEventRejections
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if(network){
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/declined",self.eventID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                //EventRejections entity is checked for data and deleted if available and saved
                NSArray *resultData = [coreDataObj getValue:@"EventRejections" eventId:self.eventID];
                if(resultData != nil)
                {
                    [coreDataObj deleteValue:@"EventRejections" eventId:self.eventID];
                }
                [coreDataObj saveValue:result attributeName:@"eventRejections" entityName:@"EventRejections" eventId:self.eventID];
                self.declinedArray = [result valueForKey:@"data"];
            }
            [self.tableView reloadData];
            [self getEventAttendees];
        }];
    }
    else
    {
        NSArray *resultData = [coreDataObj getValue:@"EventRejections" eventId:self.eventID];
        NSString *arrData;
        
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"eventRejections"];
                
            }
            if(arrData != nil)
            {
                self.declinedArray = [arrData valueForKey:@"data"];
                [self.tableView reloadData];
            }
        }
        [self getEventAttendees];
    }
}

- (void)getEventTentatives
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    CoreDataUtil *coreDataObj = [CoreDataUtil sharedInstance];
    if(network)
    {
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/maybe",self.eventID] completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error)
            {
                //EventTentatives entity is refreshed with the new copy of data
                NSArray *resultData = [coreDataObj getValue:@"EventTentatives" eventId:self.eventID];
                if(resultData != nil)
                {
                    [coreDataObj deleteValue:@"EventTentatives" eventId:self.eventID];
                }
                [coreDataObj saveValue:result attributeName:@"eventTentatives" entityName:@"EventTentatives" eventId:self.eventID];
                self.tentativesArray = [result valueForKey:@"data"];
                
            }
            [self.tableView reloadData];
            [self getEventRejections];
        }];
    }
    else //if network is not available value is fetched from EventTentatives entity
    {
        NSArray *resultData = [coreDataObj getValue:@"EventTentatives" eventId:self.eventID];
        NSString *arrData;
        if(resultData != nil)
        {
            for (NSManagedObject *info in resultData) {
                arrData = [info valueForKey:@"eventTentatives"];
            }
            if(arrData != nil)
            {
                self.tentativesArray = [arrData valueForKey:@"data"];
                [self.tableView reloadData];
            }
        }
        [self getEventRejections];
    }
}

- (void)updateRSVPStatus:(NSString*)status
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            status, @"rsvp_status",
                            nil
                            ];
    /* make the API call */
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/%@",self.eventID,status]
                                 parameters:params
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection,id result,NSError *error)
     {
         if(!error)
         {
             //weird case because maybe is returend as unsure but the other routes match RSVP status
             if([status isEqualToString:@"maybe"])
             {
                 self.RSVPStatus = @"unsure";
             }
             else
             {
                 self.RSVPStatus = status;
             }
             [self.tableView reloadData];
             [self getRSVPStatus]; //called here to update rsvp status in db
         }
         else
         {
             
             if([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryPermissions)
             {
                 UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:kNetworkStatus message:kUserDenied delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil, nil];
                 [alertView show];
             }
         }
     }];
}

#pragma mark - RSVP Action sheet

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self updateRSVPStatus:@"attending"];
            break;
        case 1:
            [self updateRSVPStatus:@"maybe"];
            break;
        case 2:
            [self updateRSVPStatus:@"declined"];
            break;
            
        default:
            break;
    }
}

#pragma mark - Submit Feedback via email
-(void)sendEmail
{
    // Email Subject
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    
    if(network){//if network is there, mail composition screen is shown else just user is alerted with offline message
        NSString *emailTitle =  [NSString stringWithFormat:@"%@ Feedback",self.title];
        // Email Content
        NSString *messageBody = @"";
        // To address
        NSArray *toRecipents = [NSArray arrayWithObject:@"gscreativelab@gmail.com"];
        if([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
            mc.mailComposeDelegate = self;
            [mc setSubject:emailTitle];
            [mc setMessageBody:messageBody isHTML:NO];
            [mc setToRecipients:toRecipents];
            [self presentViewController:mc animated:YES completion:NULL];
        }
        else
        {
            UIAlertView *alertView  = [[UIAlertView alloc]initWithTitle:@"Mail Accounts" message:@"Please configure your mail accounts to send mails" delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil, nil];
            [alertView show];
            
        }
        
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:kNetworkStatus message:kOfflinePost delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}



#pragma mark - Table view data source & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSInteger numberOfSections = 6;
    
    //if user RSVP'd and event is in the past allow option to submit feedback
    if(self.isPastEvent && [self.RSVPStatus isEqualToString:@"attending"])
    {
        numberOfSections++;
        self.isPastAndAttend = YES;
    }
    
    if(![self.RSVPStatus isEqualToString:@"not_replied"] && self.RSVPStatus != nil)
    {
        numberOfSections++; //incremented to show PostToEvent
    }
    
    
    //to show recent posts count is added to number of sections
    return numberOfSections + self.recentPostsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
    BOOL network =  [reachNet checkNetworkStatus];
    if(indexPath.section == 5)
    {
        if(network){
            //JNJLoginViewController *loginController = [[JNJLoginViewController alloc]init];
            //NSLog(@"text %@",loginController.userLabel.text);
           // if(![self.userID isEqualToString:self.organizerID])
            //{
            UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                                    @"Attend",
                                    @"Unsure",
                                    @"Decline",
                                    nil];
            [popup showInView:self.view];
//            }
//            else
//            {
//                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:kAction message:@"Organizer cannot change RSVP" delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil, nil];
//                [alertView show];
//                
//            }
        }
        else{
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:kNetworkStatus message:kOfflinePost delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil,nil];
            [alertView show];
        }
    }
    else if (indexPath.section == 6 && (self.isPastEvent && [self.RSVPStatus isEqualToString:@"attending"]))
    {
        [self sendEmail];
    }
    else if (indexPath.section ==4)
    {
        [tableView setUserInteractionEnabled:NO];
        [self getEventTentatives];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section >= 6)
    {
        return 10;
    }
    
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(section < 6)
    {
        return 1;
    }
    else
    {
        return CGFLOAT_MIN;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    switch (indexPath.section)
    {
        case 0:
        {
            GroupsPhotoTableViewCell *cell = (GroupsPhotoTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"eventPhotoDetailCellIdentifier" forIndexPath:indexPath];
            cell.groupPhotoImageView.image = self.eventImage;
            return cell;
        }
            break;
        case 1:
        {
            EventsTableViewCell *cell =  (EventsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"RSVPStatusCellIdentifier"];
            cell.eventNameLabel.text = [NSString stringWithFormat:@"Organized by %@",[[self.eventDetailDictionary valueForKey:@"owner"] valueForKey:@"name"]];
            self.organizerID = [[self.eventDetailDictionary valueForKey:@"owner"] valueForKey:@"id"];
            [cell.eventNameLabel sizeToFit];
            return cell;
        }
        case 2:
        {
            EventsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timeDateCellIdentifier"];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            NSDate *date;
            NSString *dateString = [self.eventDetailDictionary valueForKey:@"start_time"];
            cell.eventPhotoImageView.image = [[UIImage imageNamed:@"time"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];;
            if(![[self.eventDetailDictionary valueForKey:@"is_date_only"] boolValue])
            {
                [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
                date = [dateFormat dateFromString:dateString];
                [dateFormat setDateFormat:@"eee MMM dd, yyyy hh:mm"];
                cell.eventNameLabel.text = [dateFormat stringFromDate:date];
            }
            else
            {
                [dateFormat setDateFormat:@"yyyy-MM-dd"];
                date = [dateFormat dateFromString:dateString];
                [dateFormat setDateFormat:@"eee MMM dd, yyyy"];
                cell.eventNameLabel.text = [dateFormat stringFromDate:date];
            }
            return cell;
            
        }
            break;
        case 3:
        {
            EventsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timeDateCellIdentifier"];
            cell.eventNameLabel.text = [self.eventDetailDictionary valueForKey:@"location"];
            if(cell.eventNameLabel.text.length == 0)
            {
                cell.eventNameLabel.text = @"Not Specified";
            }
            cell.eventPhotoImageView.image = [[UIImage imageNamed:@"location"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            return cell;
        }
            break;
        case 4:
        {
            EventsTableViewCell *cell =  (EventsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"attendeesCellIdentifier"];
            cell.eventNameLabel.text = @"Attendees";
            cell.eventDetailsLabel.text = @"View attendee list";
            return cell;
        }
        case 5:
        {
            EventsTableViewCell *cell =  (EventsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"RSVPStatusCellIdentifier"];
            cell.eventNameLabel.text = [self.RSVPStatus uppercaseString];
            [cell.eventPhotoImageView setTintColor:[[[[UIApplication sharedApplication] delegate] window] tintColor]];
            cell.eventPhotoImageView.hidden = NO;
            if([self.RSVPStatus isEqualToString:@"unsure"])
            {
                cell.eventPhotoImageView.image = [[UIImage imageNamed:@"maybeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else if([self.RSVPStatus isEqualToString:@"attending"])
            {
                cell.eventPhotoImageView.image = [[UIImage imageNamed:@"acceptedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else if([self.RSVPStatus isEqualToString:@"declined"])
            {
                [cell.eventPhotoImageView setTintColor:[UIColor redColor]];
                cell.eventPhotoImageView.image = [[UIImage imageNamed:@"rejectedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.eventNameLabel.text = @"RSVP";
                cell.eventPhotoImageView.hidden = YES;
            }
            
            if(self.isPastEvent)
            {
                cell.userInteractionEnabled = NO;
            }
            else
            {
                cell.userInteractionEnabled = YES;
            }
            
            return cell;
        }
            break;
        case 6:
        {
            if(self.isPastAndAttend)
            {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"submitFeedbackCellIdentifier"];
                cell.textLabel.text = @"Submit Feedback";
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                return cell;
            }
            else
            {
                if(![self.RSVPStatus isEqualToString:@"not_replied"] && self.RSVPStatus != nil)
                {
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"postToGroupIdentifier"];
                    return cell;
                }
            }
        }
            break;
        case 7:
        {
            if(self.isPastAndAttend)
            {
                if(![self.RSVPStatus isEqualToString:@"not_replied"] && self.RSVPStatus != nil)
                {
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"postToGroupIdentifier"];
                    return cell;
                }
            }
        }
            break;
        default:
            break;
    }
    
    NSInteger numberOfPreviousSections;
    if(self.isPastEvent && [self.RSVPStatus isEqualToString:@"attending"])
    {
        numberOfPreviousSections = 7;
    }
    else
    {
        numberOfPreviousSections = 6;
    }
    
    if(indexPath.section > numberOfPreviousSections || (indexPath.section == numberOfPreviousSections && ([self.RSVPStatus isEqualToString:@"not_replied"] || self.RSVPStatus == nil)))
    {
        NSInteger offset = 0;
        if(indexPath.section == numberOfPreviousSections && ([self.RSVPStatus isEqualToString:@"not_replied"] || self.RSVPStatus == nil))
        {
            offset = numberOfPreviousSections;
        }
        else
        {
            offset = numberOfPreviousSections + 1;
        }
        
        RecentPostTableViewCell *cell = (RecentPostTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"groupTextCellIdentifier"];
        cell.postLabel.text = [[self.recentPostsArray objectAtIndex:(indexPath.section - offset)] valueForKey:@"message"];
        cell.authorLabel.text = [[[self.recentPostsArray objectAtIndex:(indexPath.section - offset)] valueForKey:@"from"] valueForKey:@"name"];
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        NSDate *date;
        
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
        date = [dateFormat dateFromString:[[self.recentPostsArray objectAtIndex:(indexPath.section - offset)] valueForKey:@"created_time"]];
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
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:tableView.frame];
    headerView.backgroundColor = [UIColor clearColor];
    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            return 200;
        case 4:
            return 65;
        default:
            break;
    }
    
    NSInteger numberOfPreviousSections;
    if(self.isPastEvent && [self.RSVPStatus isEqualToString:@"attending"])
    {
        numberOfPreviousSections = 7;
    }
    else
    {
        numberOfPreviousSections = 6;
    }
    
    if(indexPath.section > numberOfPreviousSections || (indexPath.section == numberOfPreviousSections && [self.RSVPStatus isEqualToString:@"not_replied"]))
    {
        NSInteger offset;
        if(indexPath.section == numberOfPreviousSections && [self.RSVPStatus isEqualToString:@"not_replied"])
        {
            offset = numberOfPreviousSections;
        }
        else
        {
            offset = numberOfPreviousSections + 1;
        }
        RecentPostTableViewCell *cell = (RecentPostTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"groupTextCellIdentifier"];
        cell.postLabel.text = [[self.recentPostsArray objectAtIndex:(indexPath.section - offset)] valueForKey:@"message"];
        
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
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
    else if([segue.identifier isEqualToString:@"postToGroupSegueIdentifier"])
    {
        ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
        BOOL network =  [reachNet checkNetworkStatus];
        if(network)
        {
            UINavigationController *navigationController = segue.destinationViewController;
            PostToGroupViewController *postToGroupViewController = (PostToGroupViewController*)navigationController.childViewControllers[0];
            postToGroupViewController.groupID = self.eventID;
        }
        else
        {
            [[CoreDataUtil sharedInstance]showOfflineAlert];
        }
    }
    
}


-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    BOOL canReturn = NO;
    //when post to event is clicked and the network is not available this segue action is not performed and user is alerted with offline message
    if([identifier isEqualToString:@"postToGroupSegueIdentifier"])
    {
        ReachabilityUtil *reachNet = [[ReachabilityUtil alloc]init];
        BOOL network =  [reachNet checkNetworkStatus];
        if(network)
        {
            canReturn = YES;
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:kNetworkStatus message:kOfflinePost delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
    else
    {
        return YES;
    }
    return canReturn;
}
@end
