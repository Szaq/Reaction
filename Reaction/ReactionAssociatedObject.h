//
//  ReactionAsociatedObject.h
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BlockTypes.h"
#import "ReactionDebug.h"

@interface ReactionAssociatedObject : NSObject

/**
 * Has reaction value generation and observation already finished?
 * If yes, than registering observers will no longer work.
 */
@property (readonly) BOOL finished;

/**
 * Has error been handled by a valid handler.
 */
@property (readonly) BOOL errorHandled;

/**
 * Last value generated by reaction or process observers.
 */
@property (readonly) NSObject *value;

/**
 * Initialize associated object.
 *
 * @param object Object with which this reaction is associated. Will be reatained untill all observers are done.
 * @return Initialized reaction associated object.
 */
- (instancetype)initWithObject:(id)object;

- (void)runBlock:(ReactionBlock)block REACTION_BLOCK_DEF onQueue:(dispatch_queue_t)queue forObject:(id)object;

- (BOOL)addThenBlock:(ThenBlock)block REACTION_BLOCK_DEF withQueue:(dispatch_queue_t)queue;
- (BOOL)addObserveBlock:(ObserveBlock)block REACTION_BLOCK_DEF withQueue:(dispatch_queue_t)queue;
- (BOOL)addProcessBlock:(ProcessBlock)block REACTION_BLOCK_DEF withQueue:(dispatch_queue_t)queue;
- (BOOL)addOnErrorBlock:(OnErrorBlock)block REACTION_BLOCK_DEF withQueue:(dispatch_queue_t)queue;

/**
 *  Cancel all observers which haven't yet been launched.
 */
- (void)removeAllObservers;

/**
 *  Notify Reaction Associated Object, that error has been handled.
 */
- (void)handleError;


#pragma mark - Unit Testing support
/**
 * Set queue on which blocks will be launched if their scheduled for main queue.
 * Used for unit testing, because test is launched on main queue.
 *
 * @param queue Queue to substitute for the main queue. Nil to reset to true main_queue.
 */
+ (void)setMainQueueSubstituteQueue:(dispatch_queue_t)queue;
@end
