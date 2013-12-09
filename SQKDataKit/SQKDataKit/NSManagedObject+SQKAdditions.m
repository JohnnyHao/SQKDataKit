//
//  NSManagedObject+SQKAdditions.m
//  SQKDataKit
//
//  Created by Luke Stringer on 05/12/2013.
//  Copyright (c) 2013 3Squared. All rights reserved.
//

#import "NSManagedObject+SQKAdditions.h"

@implementation NSManagedObject (SQKAdditions)

+ (NSString *)SQK_entityName {
    return NSStringFromClass([self class]);
}

+ (NSEntityDescription *)SQK_entityDescriptionInContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription entityForName:[self SQK_entityName] inManagedObjectContext:context];
}

+ (instancetype)SQK_insertInContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription insertNewObjectForEntityForName:[self SQK_entityName] inManagedObjectContext:context];
}

+ (NSFetchRequest *)SQK_fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:[self SQK_entityName]];
}

+ (instancetype)SQK_findOrInsertByKey:(NSString *)key
                                value:(id)value
                              context:(NSManagedObjectContext *)context
                                error:(NSError **)error {
    NSFetchRequest *request = [self SQK_fetchRequest];
    [request setFetchLimit:1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", key, value];
    [request setPredicate:predicate];
    
    NSError *localError = nil;
    NSArray *objects = [context executeFetchRequest:request error:&localError];
    
    // TODO return error
    
    id managedObject = [objects lastObject];
    if (!managedObject) {
        managedObject = [self SQK_insertInContext:context];
        [managedObject setValue:value forKey:key];
    }
    
    return managedObject;
}

- (void)SQK_deleteObject {
    [self.managedObjectContext deleteObject:self];
}

+ (void)SQK_deleteAllObjectsInContext:(NSManagedObjectContext *)context error:(NSError **)error {
    NSError *localError = nil;
    NSFetchRequest *fetchRequest = [self SQK_fetchRequest];
    NSArray *objects = [context executeFetchRequest:fetchRequest error:&localError];
    if (localError) {
        *error = localError;
        return;
    }
    [objects makeObjectsPerformSelector:@selector(SQK_deleteObject)];
}

+ (void)SQK_insertOrUpdate:(NSArray *)dictArray
            uniqueModelKey:(NSString *)modelKey
           uniqueRemoteKey:(NSString *)remoteDataKey
       propertySetterBlock:(SQKPropertySetterBlock)propertySetterBlock
                   privateContext:(NSManagedObjectContext *)context
                     error:(NSError **)error {
    
    [context performBlockAndWait:^{
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:remoteDataKey ascending:YES];
        NSArray* sortedResponse = [dictArray sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        NSArray* fetchedValues = [sortedResponse valueForKeyPath:modelKey];
        
        // Create the fetch request to get all objects matching the unique key.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[self SQK_entityDescriptionInContext:context]];
        [fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(%K IN %@)", modelKey, fetchedValues]];
        
        [fetchRequest setSortDescriptors: @[sortDescriptor]];
        
        NSError *localError = nil;
        NSArray *objectsMatchingKey = [context executeFetchRequest:fetchRequest error:&localError];
        if (localError) {
            return;
        }
        
        NSEnumerator* objectEnumerator = [objectsMatchingKey objectEnumerator];
        NSEnumerator* dictionaryEnumerator = [sortedResponse objectEnumerator];
        
        NSDictionary* dictionary;
        id object = [objectEnumerator nextObject];
        
        while (dictionary = [dictionaryEnumerator nextObject]) {
            if (object != nil && [[object valueForKey:modelKey] isEqualToString:dictionary[modelKey]]) {
                if (propertySetterBlock) {
                    propertySetterBlock(dictionary, object);
                }
                object = [objectEnumerator nextObject];
            }
            else {
                id newObject = [[self class] SQK_insertInContext:context];
                if (propertySetterBlock) {
                    propertySetterBlock(dictionary, newObject);
                }
            }
        }
 
    }];
}

@end