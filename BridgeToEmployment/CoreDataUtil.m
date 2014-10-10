//
//  CoreDataUtil.m
//  BridgeToEmployment
//
//  Created by Administrator on 17/09/14.
//  Copyright (c) 2014 JNJ. All rights reserved.
//

#import "CoreDataUtil.h"
#import <CoreData/CoreData.h>
#import <FacebookSDK/FacebookSDK.h>

@implementation CoreDataUtil

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

/**
 * Returns the instance of this class
 */
+(id)sharedInstance
{
    static CoreDataUtil *sharedInstance = nil;
    @synchronized(self) {
        if (sharedInstance == nil)
            sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

/**
 * Alerts the user to check for network connectivity
 */
-(void)showOfflineAlert
{
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:kNetworkStatus message:kOffline delegate:nil cancelButtonTitle:kCancel otherButtonTitles:nil, nil];
    [alertView show];
}

/**
 * Returns the managed object context for the application.
 * If the context doesn't already exist, it is created and bound to the persistent store coordinator for
 * the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

/**
 * Returns the managed object model for the application.
 * If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kAppName  withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

/**
 * Returns the persistent store coordinator for the application.
 * If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DataModel.sqlite"];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
        
        NSLog(@"%@ %@, %@",kUnresolved ,error, [error userInfo]);
        abort();
    }
    return _persistentStoreCoordinator;
}

/**
 * Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/**
 * Saves the passed entity
 * @param entityName - Name of the entity to save
 * @param eventId -  event Id to be saved
 * @return void
 */
-(void)saveValue:(NSValueTransformer *)result attributeName:(NSString *)attributeName entityName:(NSString *)entityName eventId:(NSString *)eventId
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSManagedObject *groupMembers;
    groupMembers = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                 inManagedObjectContext:context];
    [groupMembers setValue:result forKeyPath:attributeName];
    if (eventId != nil) {
        [groupMembers setValue:[NSString stringWithFormat:@"%@",eventId] forKeyPath:@"id"];
    }
    NSError *error = nil;
    [context save:&error];
}
/**
 * Deletes the passed entity
 * @param entityName - Name of the entity to delete
 * @param eventId -  event Id to be deleted
 * @return void
 */
-(void)deleteValue:(NSString *)entityName eventId:(NSString *)eventId
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDesc];
    if(eventId != nil){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@",eventId];
        [request setPredicate:predicate];
    }
    NSError *fetchError;
    NSError *error;
    NSArray *fetchedContacts = [context executeFetchRequest:request error:&fetchError];
    if([fetchedContacts count] != 0)
    {
        for(NSManagedObject *contact in fetchedContacts)
        {
            [context deleteObject:contact];
            
        }
    }
    [context save:&error];
}

/**
 * Retrieves value from the entity passed
 * @param entityName - Name of the entity to fetch
 * @param eventId - Corresponding event id
 */
-(NSArray *)getValue:(NSString *)entityName eventId:(NSString *)eventId
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDesc];
    if(eventId != nil){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@",eventId];
        [request setPredicate:predicate];
    }
    NSError *error;
    NSArray *retrievedArr = [context executeFetchRequest:request error:&error];
    if(retrievedArr != nil && [retrievedArr count]>0)
    {
        return retrievedArr;
    }
    else
    {
        return nil;
    }
}

@end
