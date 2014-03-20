//
//  NSObject+Reaction.m
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import "NSObject+Reaction.h"
#import "NSObject+ReactionAssociatedObject.h"

REACTION_SET_LOG_LEVEL;

@implementation NSObject (Reaction)

+ (instancetype)reactionWithBlock:(ReactionBlock)block {
  NSObject *object = [[NSObject alloc] init];
  REACTION_LOG_DEBUG(@"%@ Creating reaction block :%@", object, block);
  [[object reactionObjectEnsureCreated] runBlock:block REACTION_BLOCK_FORWARD_UNNAMED
                                         onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                         forObject:self];
  return object;
}

+ (instancetype)reactionWithBlockOnMainQueue:(ReactionBlock)block {
  NSObject *object = [[NSObject alloc] init];
  REACTION_LOG_DEBUG(@"%@ Creating reaction block :%@", object, block);
  [[object reactionObjectEnsureCreated] runBlock:block REACTION_BLOCK_FORWARD_UNNAMED
                                         onQueue:dispatch_get_main_queue()
                                       forObject:self];
  return object;
}

+ (instancetype)reactionWithBlock:(ReactionBlock)block onQueue:(dispatch_queue_t)queue {
  NSObject *object = [[NSObject alloc] init];
  REACTION_LOG_DEBUG(@"%@ Creating reaction block :%@", object, block);
  [[object reactionObjectEnsureCreated] runBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:queue forObject:self];
  return object;
}

+ (instancetype) error:(NSError *)error {
  NSObject *object = [[NSObject alloc] init];
  REACTION_LOG_DEBUG(@"%@ Creating error reaction %@ with error : %@", self, object, error);
  [object setReactionError:error];
  return object;
}

@end

#ifdef REACTION_DEBUG

@implementation NSObject (ReactionDebug)

+ (instancetype)reactionWithBlock:(ReactionBlock)block withName:(NSString *)name {
  NSObject *object = [[NSObject alloc] init];
  REACTION_LOG_DEBUG(@"%@ Creating reaction block :%@", object, name);
  [[object reactionObjectEnsureCreated] runBlock:block
                                        withName:name
                                         onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                       forObject:self];
  return object;
}

+ (instancetype)reactionWithBlockOnMainQueue:(ReactionBlock)block withName:(NSString *)name {
  NSObject *object = [[NSObject alloc] init];
  REACTION_LOG_DEBUG(@"%@ Creating reaction block :%@", object, name);
  [[object reactionObjectEnsureCreated] runBlock:block withName:name onQueue:dispatch_get_main_queue() forObject:self];
  return object;
}

+ (instancetype)reactionWithBlock:(ReactionBlock)block
                         withName:(NSString *)name
                          onQueue:(dispatch_queue_t)queue {
  NSObject *object = [[NSObject alloc] init];
  REACTION_LOG_DEBUG(@"%@ Creating reaction block :%@", object, name);
  [[object reactionObjectEnsureCreated] runBlock:block withName:name onQueue:queue forObject:self];
  return object;
}

+ (instancetype) error:(NSError *)error {
  NSObject *object = [[NSObject alloc] init];
  REACTION_LOG_DEBUG(@"Creating error reaction %@ with error : %@", object, error);
  [object setReactionError:error];
  return object;
}


@end

#endif
