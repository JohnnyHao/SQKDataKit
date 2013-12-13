//
//  DataImportOperation.m
//  SQKDataKit
//
//  Created by Luke Stringer on 10/12/2013.
//  Copyright (c) 2013 3Squared. All rights reserved.
//

#import "OptimisedImportOperation.h"
#import "Commit.h"
#import "NSManagedObject+SQKAdditions.h"

@implementation OptimisedImportOperation

- (void)updatePrivateContext:(NSManagedObjectContext *)context usingJSON:(id)json {
    NSDate *beforeDate = [NSDate date];
    
    NSInteger totalCount = [json count];
    __block NSInteger currentIndex = 0;
    
    [Commit SQK_insertOrUpdate:json
                uniqueModelKey:@"sha"
               uniqueRemoteKey:@"sha"
           propertySetterBlock:^(NSDictionary *dictionary, Commit *commit) {
               commit.authorName = dictionary[@"commit"][@"committer"][@"name"];
               commit.authorEmail = dictionary[@"commit"][@"committer"][@"email"];
               commit.date = [self dateFromJSONString:dictionary[@"commit"][@"committer"][@"date"]];
               commit.message = dictionary[@"commit"][@"message"];
               commit.url = dictionary[@"html_url"];
               
               ++currentIndex;
               if (self.progressBlock) {
                   self.progressBlock(currentIndex, totalCount);
               }
           }
                privateContext:context
                         error:nil];
    
     NSLog(@"Optimised took: %f", [[NSDate date] timeIntervalSinceDate:beforeDate]);
}

- (NSDate *)dateFromJSONString:(NSString *)jsonString {
    NSDate *date = [[self dateFormatter] dateFromString:jsonString];
    return date;
}

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    }
    return dateFormatter;
}

@end
