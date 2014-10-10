//
//  ImageUtils.h
//  BridgeToEmployment
//
//  Created by Administrator on 25/09/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject
- (void)saveImage: (UIImage*)image fileName:(NSString *)fileName;
- (UIImage*)loadImage:(NSString *)fileName;
@end
