//
//  ReachabilityUtil.m
//  BridgeToEmployment
//
//  Created by Administrator on 18/09/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "ReachabilityUtil.h"
@implementation ReachabilityUtil

/**
 * Checks the network availability
 * @return true if network is available else false
 */
-(BOOL)checkNetworkStatus
{
    Reachability *myNetwork = [Reachability reachabilityWithHostName:@"www.facebook.com"];
    NetworkStatus myStatus = [myNetwork currentReachabilityStatus];
    BOOL returnValue = NO;
    
    switch (myStatus) {
        case NotReachable:
            break;
            
        case ReachableViaWWAN:
            returnValue = YES;
            break;
            
        case ReachableViaWiFi:
            returnValue = YES;
            break;
            
        default:
            break;
    }
    return returnValue;
}
@end
