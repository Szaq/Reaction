//
//  ReactionAsociatedObject.m
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//
#import "ReactionAssociatedObject.h"
#import "NSObject+ReactionAssociatedObject.h"
#import "VoidReaction.h"

REACTION_SET_LOG_LEVEL;

static dispatch_queue_t MainQueueSubstitute = nil;

typedef enum {
  ObserverTypeThen,
  ObserverTypeObserve,
  ObserverTypeProcess,
  ObserverTypeOnError,
} ObserverType;

@interface Observer : NSObject

@property(nonatomic) ObserverType type;
@property(nonatomic, copy) id block;
@property(nonatomic) dispatch_queue_t queue;

#ifdef REACTION_DEBUG
@property (nonatomic) NSString *name;
#endif//REACTION_DEBUG

+ (instancetype)Then:(ThenBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue;
+ (instancetype)Observe:(ObserveBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue;
+ (instancetype)Process:(id (^)(id))block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue;
+ (instancetype)OnError:(void (^)(NSError *))block REACTION_BLOCK_DEF
                onQueue:(dispatch_queue_t)queue;

@end

@implementation Observer

+ (instancetype)Then:(ThenBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue {
  Observer *observer = [[Observer alloc] init];
  observer.type = ObserverTypeThen;
  observer.block = block;
  observer.queue = queue;
  REACTION_SETUP_OBSERVER;
  return observer;
}

+ (instancetype)Observe:(ObserveBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue {
  Observer *observer = [[Observer alloc] init];
  observer.type = ObserverTypeObserve;
  observer.block = block;
  observer.queue = queue;
  REACTION_SETUP_OBSERVER;
  return observer;
}

+ (instancetype)Process:(id (^)(id))block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue {
  Observer *observer = [[Observer alloc] init];
  observer.type = ObserverTypeProcess;
  observer.block = block;
  observer.queue = queue;
  REACTION_SETUP_OBSERVER;
  return observer;
}

+ (instancetype)OnError:(void (^)(NSError *))block REACTION_BLOCK_DEF
                onQueue:(dispatch_queue_t)queue {
  Observer *observer = [[Observer alloc] init];
  observer.type = ObserverTypeOnError;
  observer.block = block;
  observer.queue = queue;
  REACTION_SETUP_OBSERVER;
  return observer;
}

@end

@interface ReactionAssociatedObject () {
  NSMutableArray *_observers;
  /// Has error been called.
  BOOL _errored;
#ifdef REACTION_FUNKY_NAMES
  /// Funky name for this reaction associated object
  NSString *_name;
#endif

}

/// Retain object as long as observing process is not finished
@property(nonatomic) id associatedObject;

@end

@implementation ReactionAssociatedObject

#pragma mark - Object lifecycle

- (instancetype)initWithObject:(id)object {
  if ((self = [super init])) {
#ifdef REACTION_FUNKY_NAMES
    _name = REAGetFunkyName(self);
#endif
    REACTION_LOG_DEBUG(@"Intializing RAO (%@) for %@", self, object);
    _observers = [NSMutableArray array];
    _finished = NO;
    _errored = NO;
    self.associatedObject = object;
  }
  return self;
}

- (void)finishReaction {
  REACTION_LOG_DEBUG(@"RAO %@ has finished running observers", self);
  // No viable observer found
  _finished = YES;
  // Break dependency cycle
  self.associatedObject = nil;
}

- (void)restartReactionForObject:(id)object {
  REACTION_LOG_DEBUG(@"RAO %@ has restarting for %@", self, object);
  // No viable observer found
  _finished = NO;
  self.associatedObject = object;
}

#pragma mark - Running

- (void)runNextObserverInQueue:(dispatch_queue_t)queue {
  REACTION_LOG_DEBUG(@"RAO (%@) trying to run next observer", self);
  NSError *error = [_value reactionError];

  __block Observer *observerToLaunch = nil;
  // Launch next observer
  @synchronized(_observers) {
    if (error) {
      REACTION_LOG_DEBUG(@"RAO (%@) value is an error", self);
      _errored = YES;
    }

    // Skip if there are no observers
    if (!_observers.count) {
      REACTION_LOG_DEBUG(@"RAO (%@) no observers found", self);
      [self finishReaction];
      return;
    }

    __block NSInteger observerToLaunchIdx = 0;

    // If we have an error, then find first onErrorObserver
    if (error) {
      REACTION_LOG_DEBUG(@"RAO (%@) searching for OnError observer", self);
      [_observers enumerateObjectsUsingBlock:^(Observer *observer,
                                               NSUInteger idx, BOOL *stop) {
          if (observer.type == ObserverTypeOnError) {
            observerToLaunch = observer;
            *stop = YES;
          }
      }];
    }
    // For success find first observer other than OnError.
    else {
      REACTION_LOG_DEBUG(@"RAO (%@) searching for normal observer", self);
      [_observers enumerateObjectsUsingBlock:^(Observer *observer,
                                               NSUInteger idx, BOOL *stop) {
          if (observer.type != ObserverTypeOnError) {
            observerToLaunch = observer;
            *stop = YES;
          }
      }];
    }

    if (observerToLaunch) {
      [_observers removeObjectsInRange:NSMakeRange(0, observerToLaunchIdx + 1)];
    } else {
      [_observers removeAllObjects];
    }

    if (!observerToLaunch) {
      REACTION_LOG_DEBUG(@"RAO (%@) no valid observer found", self);
      [self finishReaction];
      return;
    }
  }

  dispatch_block_t dispatchBlock = ^{
      REACTION_LOG_INFO(@"RAO (%@) running observer %@", self, observerToLaunch.name);
      switch (observerToLaunch.type) {
        case ObserverTypeThen:
          ((ThenBlock)observerToLaunch.block)();
          break;
        case ObserverTypeObserve:
          ((ObserveBlock)observerToLaunch.block)(_value);
          break;
        case ObserverTypeProcess:
          _value = ((ProcessBlock)observerToLaunch.block)(_value);
          // We must have NSObject object returned from reaction returning
          // methods, even if we don't want any.
          if ([_value isKindOfClass:[VoidReaction class]]) {
            _value = nil;
          }
          break;
        case ObserverTypeOnError:
          [self handleError];
          ((OnErrorBlock)observerToLaunch.block)(error);
          // Only one OnError should be launched
          break;
        default:
          break;
      }
      REACTION_LOG_DEBUG(@"RAO (%@) observer finished running", self);
      [self runNextObserverInQueue:observerToLaunch.queue];
  };

  if ((observerToLaunch.queue == queue) || !observerToLaunch.queue) {
    REACTION_LOG_DEBUG(@"RAO (%@) running observer without GCD", self);
    // Just run it in the same queue in the same task
    // Consider scheduling as separate block even on the same queue
    dispatchBlock();
  } else {
    // Check if we need to substitute main queue for unit testing purposes
    if (MainQueueSubstitute) {
      if (observerToLaunch.queue == dispatch_get_main_queue()) {
        observerToLaunch.queue = MainQueueSubstitute;
      }
    }
    REACTION_LOG_DEBUG(@"RAO (%@) scheduling observer to its queue", self);
    dispatch_async(observerToLaunch.queue, dispatchBlock);
  }
}

- (void)runBlock:(ReactionBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue forObject:(id)object {
  block = [block copy];
  dispatch_block_t dispatchBlock = ^{
    // Generate value
    REACTION_LOG_DEBUG(@"RAO (%@) running block %@", self, name);
    _value = block();
    REACTION_LOG_DEBUG(@"RAO (%@) block finished %@", self, name);
    // We must have NSObject object returned from reaction returning methods,
    // even if we don't want any.
    if ([_value isKindOfClass:[VoidReaction class]]) {
      REACTION_LOG_DEBUG(@"RAO (%@) Clearing value due to VoidReaction.", self);
      _value = nil;
    }
    [self runNextObserverInQueue:queue];
  };
  // Check if we need to substitute main queue for unit testing purposes
  if (MainQueueSubstitute) {
    if (queue == dispatch_get_main_queue()) {
      queue = MainQueueSubstitute;
    }
  }
  // Directly run block. We no longer need schedule launchin async task fo next
  // runlooop.
  // Observers will detect finished AssociatedObject and behave accordingly
  REACTION_LOG_DEBUG(@"RAO (%@) scheduling block %@ to its queue", self, name);
  [self restartReactionForObject:object];
  dispatch_async(queue, dispatchBlock);
}

#pragma mark - Block scheduling

- (BOOL)addThenBlock:(ThenBlock)block REACTION_BLOCK_DEF withQueue:(dispatch_queue_t)queue {
  @synchronized(_observers) {
    if (self.finished || _errored) {
      REACTION_LOG_INFO(
          @"RAO (%@) finished (%d) or errored (%d) and failed to add then block: %@",
          self, _finished, _errored, name);
      return NO;
    }
    REACTION_LOG_INFO(@"RAO (%@) adding then block: %@", self, name);
    [_observers addObject:[Observer Then:block REACTION_BLOCK_FORWARD onQueue:queue]];
    return YES;
  }
}

- (BOOL)addObserveBlock:(ObserveBlock)block REACTION_BLOCK_DEF withQueue:(dispatch_queue_t)queue {
  @synchronized(_observers) {
    if (self.finished || _errored) {
      REACTION_LOG_INFO(
                @"RAO (%@) finished (%d) or errored (%d) and failed to add  observe block: %@",
                self, _finished, _errored, name);
      return NO;
    }
    REACTION_LOG_INFO(@"RAO (%@) adding observe block: %@", self, name);
    [_observers addObject:[Observer Observe:block REACTION_BLOCK_FORWARD onQueue:queue]];
    return YES;
  }
}

- (BOOL)addProcessBlock:(id (^)(id))block REACTION_BLOCK_DEF withQueue:(dispatch_queue_t)queue {
  @synchronized(_observers) {
    if (self.finished || _errored) {
      REACTION_LOG_INFO(
                @"RAO (%@) finished (%d) or errored (%d) and failed to add process block: %@",
                self, _finished, _errored, name);
      return NO;
    }
    REACTION_LOG_INFO(@"RAO (%@) adding process block: %@", self, name);
    [_observers addObject:[Observer Process:block REACTION_BLOCK_FORWARD onQueue:queue]];
    return YES;
  }
}

- (BOOL)addOnErrorBlock:(void (^)(NSError *))block REACTION_BLOCK_DEF
              withQueue:(dispatch_queue_t)queue {
  @synchronized(_observers) {
    if (self.finished || _errorHandled) {
      REACTION_LOG_INFO(
                @"RAO (%@) finished (%d) or error has been already handled (%d) and failed to add OnError block: %@",
                self, _finished, _errorHandled, name);
      return NO;
    }
    REACTION_LOG_INFO(@"RAO (%@) adding OnError block: %@", self, name);
    [_observers addObject:[Observer OnError:block REACTION_BLOCK_FORWARD onQueue:queue]];
    return YES;
  }
}

- (void)removeAllObservers {
  @synchronized(_observers) {
    [_observers removeAllObjects];
  }
}

- (void)handleError {
  _errorHandled = YES;
  [self removeAllObservers];
}

- (NSString *)description {
#ifdef REACTION_FUNKY_NAMES
  return _name;
#else
  return [NSString stringWithFormat:@"%p", self];
#endif
}

#pragma mark - Unit testing

+ (void)setMainQueueSubstituteQueue:(dispatch_queue_t)queue {
  MainQueueSubstitute = queue;
}

@end
