//
//  ImageUtils.m
//  BridgeToEmployment
//
//  Created by Administrator on 25/09/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

/**
 * TO write the image content in a local file
 * @param image - Image to be saved
 * @param fileName - name of the file to save the image
 * @return void
 */
 
- (void)saveImage: (UIImage*)image fileName:(NSString *)fileName
{
    if (image != nil)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString* path = [documentsDirectory stringByAppendingPathComponent:
                          fileName ];
        NSData* data = UIImagePNGRepresentation(image);
        [data writeToFile:path atomically:YES];
    }
}

/**
 * TO load image content from the local file
 * @param fileName - name of the file from which image should be retrieved
 * @return image - Fetched image
 */
- (UIImage*)loadImage:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:
                      fileName ];
    UIImage* image = [UIImage imageWithContentsOfFile:path];
    return image;
}

@end
