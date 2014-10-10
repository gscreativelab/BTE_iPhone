//
//  GAHelper.m
//  Mentis Mobile App
//
//  Created by Kurt Prenger on 7/8/14.
//  Copyright (c) 2014 Janssen R&D. This file contains the trade secrets of Johnson & Johnson. No part may be reproduced or transmitted in any form by any means or for any purpose without the express written permission of Johnson & Johnson. All rights reserved.
//
//  Centralized helper for sending Google Analytics tracking
//

#import "GAHelper.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@implementation GAHelper

+ (void)trackEventWithCategory:(NSString *)category andAction:(NSString *)action
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                          action:action
                                                           label:nil
                                                       value:nil] build]];
}

+ (void)trackTimingWithCategory:(NSString *)category
                           name:(NSString *)name
                          start:(NSDate *)started
                         andEnd:(NSDate *)ended
{
    //NSTimeInterval is in seconds, but GA expects milliseconds. Need to multiply this by 1000 later
    //Also, GA expects whole numbers without decimals, so need to convert to an NSInteger (from double)
    //
    NSTimeInterval loadTime = [ended timeIntervalSinceDate:started];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createTimingWithCategory:category
                                                         interval:[NSNumber numberWithInteger:(NSInteger)(loadTime * 1000)]
                                                             name:name
                                                            label:nil] build]];
}

+ (void)trackCustomDimensionIndex:(NSInteger)index withValue:(NSString *)value
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker set:[GAIFields customDimensionForIndex:index] value:value];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

+ (void)trackScreenName:(NSString *)name
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker set:kGAIScreenName value:name];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

@end
