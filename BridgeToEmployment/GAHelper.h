//
//  GAHelper.h
//  Mentis Mobile App
//
//  Created by Kurt Prenger on 7/8/14.
//  Copyright (c) 2014 Janssen R&D. This file contains the trade secrets of Johnson & Johnson. No part may be reproduced or transmitted in any form by any means or for any purpose without the express written permission of Johnson & Johnson. All rights reserved.
//
//  Centralized helper for sending Google Analytics tracking
//

#import <Foundation/Foundation.h>

@interface GAHelper : NSObject

+ (void)trackEventWithCategory:(NSString *)category andAction:(NSString *)action;
+ (void)trackTimingWithCategory:(NSString *)category
                           name:(NSString *)name
                          start:(NSDate *)started
                         andEnd:(NSDate *)ended;
+ (void)trackCustomDimensionIndex:(NSInteger)index withValue:(NSString *)value;
+ (void)trackScreenName:(NSString *)name;

@end
