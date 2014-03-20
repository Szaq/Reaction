//
//  Reaction.m
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import "Reaction.h"

#import "NSObject+Reaction.h"
#import "NSObject+ReactionObservation.h"

@implementation Reaction
- (NSNumber *)computeNumber:(BOOL)useCache {
  if (useCache) {
    return @12;
  }
  else {
    return [NSNumber reactionWithBlock:^NSObject *{
      BOOL succeeded = (rand() % 2) == 0;
      if (succeeded) {
        return @0x04e;
      }
      else {
        return [NSNumber error:[NSError errorWithDomain:@"Failed to generate value" code:0 userInfo:nil]];
      }
    }];
  }
}

- (void)testExample
{
  [[[[[self computeNumber:NO] then:^{
    //Do some code
  }] then:^{
    //Code executed afterwards
  }] then:^{
    //And then...
  }] onError:^(NSError *error) {
    //Oh noes error
  }];
  
  [[self computeNumber:YES] observeOnSameQueue:^(NSObject *value) {
    //Do some more code
    
    
  }];
  
  [[[[[self computeNumber:YES]
      process:^NSObject *(NSNumber *value) {
        return [NSString stringWithFormat:@"Formatted %@", value];
      }]
     process:^NSObject *(NSObject *value) {
       return [(NSString *)value stringByAppendingString:@"Text"];
     }]
    observe:^(NSObject *value) {
      NSLog(@"%@", value);
    }]
   onError:^(NSError *error) {
     NSLog(@"Error executing code: %@", error);
   }];
}
@end
