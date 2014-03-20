//
//  TestSemaphor.m
//  BillsApp
//
//  Created by Marin Todorov on 17/01/2012.
//  Copyright (c) 2012 Marin Todorov. All rights reserved.
//

#import "TestSemaphore.h"

@implementation TestSemaphore

@synthesize flags;

+(TestSemaphore *)sharedInstance
{   
    static TestSemaphore *sharedInstance = nil;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        sharedInstance = [TestSemaphore alloc];
        sharedInstance = [sharedInstance init];
    });
    
    return sharedInstance;
}

-(id)init
{
    self = [super init];
    if (self != nil) {
        self.flags = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

-(void)dealloc
{
    self.flags = nil;
}

-(BOOL)isLifted:(NSString*)key
{
    return [self.flags objectForKey:key]!=nil;
}

-(void)lift:(NSString*)key
{
    [self.flags setObject:@"YES" forKey: key];
}

-(void)waitForKey:(NSString*)key
{
  //Fast exit
  if ([[TestSemaphore sharedInstance] isLifted: key]) {
    return;
  }
  
    BOOL keepRunning = YES;
    while (keepRunning && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1f]]) {
        keepRunning = ![[TestSemaphore sharedInstance] isLifted: key];
    }

}

-(void)waitForKey:(NSString*)key timeout:(NSTimeInterval)timeout
{
  //Fast exit
  if ([[TestSemaphore sharedInstance] isLifted: key]) {
    return;
  }
  
  BOOL keepRunning = YES;
  NSDate *now = [NSDate dateWithTimeIntervalSinceNow:timeout];
  while (keepRunning && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1f]]) {
    keepRunning = ![[TestSemaphore sharedInstance] isLifted: key]
    && ([[NSDate date] compare:now] == NSOrderedDescending);
  }
  
}

@end
