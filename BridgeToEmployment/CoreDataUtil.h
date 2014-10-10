//
//  CoreDataUtil.h
//  BridgeToEmployment
//
//  Created by Administrator on 17/09/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreData/CoreData.h"

@interface CoreDataUtil : NSObject
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+(id)sharedInstance;
-(void)showOfflineAlert;
-(NSArray *)getValue:(NSString *)entityName eventId:(NSString *)eventId;
-(void)deleteValue:(NSString *)entityName eventId:(NSString *)eventId;
-(void)saveValue:(NSValueTransformer *)result attributeName:(NSString *)attributeName entityName:(NSString *)entityName eventId:(NSString *)eventId;
@end
