//
//  NSObject+ReactionObservation.m
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import "NSObject+ReactionObservation.h"
#import "NSObject+ReactionAssociatedObject.h"
#import "VoidReaction.h"

REACTION_SET_LOG_LEVEL;

#pragma mark - Then

@implementation NSObject (ReactionObservation)
- (instancetype)then:(ThenBlock)block {
  // Immediate value - run it in specified queue
  [self addOrRunThenBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:dispatch_get_main_queue()];
  return self;
}

- (instancetype)thenOnSameQueue:(ThenBlock)block {
  // Immediate value - run it in main queue
  [self addOrRunThenBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:nil];
  return self;
}

- (instancetype)thenAsync:(ThenBlock)block {
  [self addOrRunThenBlock:block REACTION_BLOCK_FORWARD_UNNAMED
                  onQueue:dispatch_get_global_queue(
                              DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  return self;
}

- (instancetype)then:(ThenBlock)block onQueue:(dispatch_queue_t)queue {
  [self addOrRunThenBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:queue];
  return self;
}

- (void)addOrRunThenBlock:(ThenBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue {
  @synchronized(self) {
    REACTION_LOG_DEBUG(@"%@ Add or run then block : %@",self, name);
    ReactionAssociatedObject *reaction = [self reactionObject];
    if (!reaction || ![reaction addThenBlock:block REACTION_BLOCK_FORWARD withQueue:queue]) {
      NSObject *value = reaction ? reaction.value : self;
      if ([value reactionError]) {
        REACTION_LOG_DEBUG(@"Value %@ was an error. Skipping running then blok %@", value, block);
        // Skip on error
        return;
      }
      REACTION_LOG_DEBUG(@"Running then block : %@", block);
      reaction = [self reactionObjectEnsureCreated];
      [reaction runBlock:^id {
        block();
        return value;
      } REACTION_BLOCK_FORWARD_WRAPPED
                 onQueue:queue ? queue : dispatch_get_main_queue()
               forObject:self];
    }
  }
}

#pragma mark - Observe

- (instancetype)observe:(ObserveBlock)block {
  // Immediate value - run it in specified queue
  [self addOrRunObserveBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:dispatch_get_main_queue()];
  return self;
}

- (instancetype)observeOnSameQueue:(ObserveBlock)block {
  // Immediate value - run it in specified queue
  [self addOrRunObserveBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:nil];
  return self;
}

- (instancetype)observeAsync:(ObserveBlock)block {
  [self addOrRunObserveBlock:block REACTION_BLOCK_FORWARD_UNNAMED
                     onQueue:dispatch_get_global_queue(
                                 DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  return self;
}

- (instancetype)observe:(ObserveBlock)block onQueue:(dispatch_queue_t)queue {
  [self addOrRunObserveBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:queue];
  return self;
}

- (void)addOrRunObserveBlock:(ObserveBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue {
  @synchronized(self) {
    REACTION_LOG_DEBUG(@"%@ Add or run observe block : %@", self, name);
    ReactionAssociatedObject *reaction = [self reactionObject];
    if (!reaction || ![reaction addObserveBlock:block REACTION_BLOCK_FORWARD withQueue:queue]) {
      NSObject *value = reaction ? reaction.value : self;
      if ([value reactionError]) {
        REACTION_LOG_DEBUG(@"Value %@ was an error. Skipping running observe blok %@", value, block);
        // Skip on error
        return;
      }
      REACTION_LOG_DEBUG(@"Running observe block : %@", block);
      reaction = [self reactionObjectEnsureCreated];
      [reaction runBlock:^id {
                           block(value);
                           return value;
                         } REACTION_BLOCK_FORWARD_WRAPPED
                 // If we got nil here it means we should run on the same queue.
                 // but since we got immediate value
                 // Let's assume we're on main queue.
                 onQueue:queue ? queue : dispatch_get_main_queue()
               forObject:self];
    }
  }
}

#pragma mark - Process

- (instancetype)process:(ProcessBlock)block {
  // Immediate value - run it in specified queue
  [self addOrRunProcessBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:nil];
  return self;
}

- (instancetype)processOnMainQueue:(ProcessBlock)block {
  // Immediate value - run it in specified queue
  [self addOrRunProcessBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:dispatch_get_main_queue()];
  return self;
}

- (instancetype)processAsync:(ProcessBlock)block {
  [self addOrRunProcessBlock:block REACTION_BLOCK_FORWARD_UNNAMED
                     onQueue:dispatch_get_global_queue(
                                 DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  return self;
}

- (instancetype)process:(ProcessBlock)block onQueue:(dispatch_queue_t)queue {
  [self addOrRunProcessBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:queue];
  return self;
}

- (void)addOrRunProcessBlock:(ProcessBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue {
  @synchronized(self) {
    REACTION_LOG_DEBUG(@"%@ Add or run process block : %@",self, name);
    ReactionAssociatedObject *reaction = [self reactionObject];
    if (!reaction || ![reaction addProcessBlock:block REACTION_BLOCK_FORWARD withQueue:queue]) {
      NSObject *value = reaction ? reaction.value : self;
      if ([value reactionError]) {
        REACTION_LOG_DEBUG(@"Value %@ was an error. Skipping running process blok %@", value, block);
        // Skip on error
        return;
      }

      REACTION_LOG_DEBUG(@"Running process block : %@", block);
      reaction = [self reactionObjectEnsureCreated];
      [reaction runBlock:^id { return block(value); } REACTION_BLOCK_FORWARD_WRAPPED
                 onQueue:queue ? queue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
               forObject:self
       ];
    }
  }
}

#pragma mark - OnError

- (instancetype)onError:(OnErrorBlock)block {
  // Immediate value - run it in specified queue
  [self addOrRunOnErrorBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:dispatch_get_main_queue()];
  return self;
}

- (instancetype)onErrorOnSameQueue:(OnErrorBlock)block {
  // Immediate value - run it in specified queue
  [self addOrRunOnErrorBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:nil];
  return self;
}

- (instancetype)onErrorAsync:(OnErrorBlock)block {
  [self addOrRunOnErrorBlock:block REACTION_BLOCK_FORWARD_UNNAMED
                     onQueue:dispatch_get_global_queue(
                                 DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  return self;
}

- (instancetype)onError:(OnErrorBlock)block onQueue:(dispatch_queue_t)queue {
  [self addOrRunOnErrorBlock:block REACTION_BLOCK_FORWARD_UNNAMED onQueue:queue];
  return self;
}

- (void)addOrRunOnErrorBlock:(OnErrorBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue {
  @synchronized(self) {
    REACTION_LOG_DEBUG(@"%@ Add or run OnError block : %@",self, name);
    ReactionAssociatedObject *reaction = [self reactionObject];
    
    if (!reaction || ![reaction addOnErrorBlock:block REACTION_BLOCK_FORWARD withQueue:queue]) {
      NSObject *value = reaction ? reaction.value : self;
      NSError *error = [value reactionError];
      if (!error || reaction.errorHandled) {
        REACTION_LOG_DEBUG(@"Value %@ error was handled or there were no error. Skipping running OnError blok %@",
                           value,
                           name);
        // Skip if there were no error
        return;
      }
      
      REACTION_LOG_DEBUG(@"Running OnError block : %@", block);
      reaction = [self reactionObjectEnsureCreated];
      // We got an error and we are the first OnError Observer. Skip rest.
      [reaction runBlock:^id {
        block(error);
        [reaction handleError];
        return value;
      } REACTION_BLOCK_FORWARD_WRAPPED
                 onQueue:queue ? queue : dispatch_get_main_queue()
               forObject:self];
    }
  }
}

- (void)cancelAllObservers {
  [[self reactionObject] removeAllObservers];
}

@end

#ifdef REACTION_DEBUG

@implementation NSObject (ReactionObservationDebug)
- (instancetype)then:(ThenBlock)block withName:(NSString *)name {
  // Immediate value - run it in specified queue
  [self addOrRunThenBlock:block withName:name onQueue:dispatch_get_main_queue()];
  return self;
}

- (instancetype)thenOnSameQueue:(ThenBlock)block withName:(NSString *)name {
  // Immediate value - run it in main queue
  [self addOrRunThenBlock:block withName:name onQueue:nil];
  return self;
}

- (instancetype)thenAsync:(ThenBlock)block withName:(NSString *)name {
  [self addOrRunThenBlock:block
                 withName:name
                  onQueue:dispatch_get_global_queue(
                                                    DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  return self;
}

- (instancetype)then:(ThenBlock)block withName:(NSString *)name onQueue:(dispatch_queue_t)queue {
  [self addOrRunThenBlock:block withName:name onQueue:queue];
  return self;
}

- (instancetype)observe:(ObserveBlock)block withName:(NSString *)name {
  // Immediate value - run it in specified queue
  [self addOrRunObserveBlock:block withName:name onQueue:dispatch_get_main_queue()];
  return self;
}

- (instancetype)observeOnSameQueue:(ObserveBlock)block withName:(NSString *)name {
  // Immediate value - run it in specified queue
  [self addOrRunObserveBlock:block withName:name onQueue:nil];
  return self;
}

- (instancetype)observeAsync:(ObserveBlock)block withName:(NSString *)name {
  [self addOrRunObserveBlock:block
                    withName:name
                     onQueue:dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  return self;
}

- (instancetype)observe:(ObserveBlock)block withName:(NSString *)name onQueue:(dispatch_queue_t)queue {
  [self addOrRunObserveBlock:block withName:name onQueue:queue];
  return self;
}

- (instancetype)process:(ProcessBlock)block withName:(NSString *)name {
  // Immediate value - run it in specified queue
  [self addOrRunProcessBlock:block withName:name onQueue:nil];
  return self;
}

- (instancetype)processOnMainQueue:(ProcessBlock)block withName:(NSString *)name {
  // Immediate value - run it in specified queue
  [self addOrRunProcessBlock:block withName:name onQueue:dispatch_get_main_queue()];
  return self;
}

- (instancetype)processAsync:(ProcessBlock)block withName:(NSString *)name {
  [self addOrRunProcessBlock:block
                    withName:name
                     onQueue:dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  return self;
}

- (instancetype)process:(ProcessBlock)block withName:(NSString *)name onQueue:(dispatch_queue_t)queue {
  [self addOrRunProcessBlock:block withName:name onQueue:queue];
  return self;
}

- (instancetype)onError:(OnErrorBlock)block withName:(NSString *)name {
  // Immediate value - run it in specified queue
  [self addOrRunOnErrorBlock:block withName:name onQueue:dispatch_get_main_queue()];
  return self;
}

- (instancetype)onErrorOnSameQueue:(OnErrorBlock)block withName:(NSString *)name {
  // Immediate value - run it in specified queue
  [self addOrRunOnErrorBlock:block withName:name onQueue:nil];
  return self;
}

- (instancetype)onErrorAsync:(OnErrorBlock)block withName:(NSString *)name {
  [self addOrRunOnErrorBlock:block
                    withName:name
                     onQueue:dispatch_get_global_queue(
                                                       DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
  return self;
}

- (instancetype)onError:(OnErrorBlock)block withName:(NSString *)name onQueue:(dispatch_queue_t)queue {
  [self addOrRunOnErrorBlock:block withName:name onQueue:queue];
  return self;
}

@end

#endif//REACTION_DEBUG
