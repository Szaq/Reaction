//
//  NSObject+Reaction.h
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlockTypes.h"
#import "ReactionDebug.h"

@interface NSObject (Reaction)

/**
 *  Reaction which will run assynchronously on global async queue and return value.
 *  This value will be used as a response.
 *
 *  @param block Block which will return response value.
 *
 *  @return Temporary value on which observers may subscribe.
 */
+ (instancetype)reactionWithBlock:(ReactionBlock)block;

/**
 *  Reaction which will run assynchronously on main queue and return value.
 *  This value will be used as a response.
 *
 *  @param block Block which will return response value.
 *
 *  @return Temporary value on which observers may subscribe.
 */
+ (instancetype)reactionWithBlockOnMainQueue:(ReactionBlock)block;

/**
 *  Reaction which will run assynchronously on specified queue and return value.
 *  This value will be used as a response.
 *
 *  @param block Block which will return response value.
 *
 *  @return Temporary value on which observers may subscribe.
 */
+ (instancetype)reactionWithBlock:(ReactionBlock)block onQueue:(dispatch_queue_t)queue;

/**
 *  Notify observers, that reaction block failed to return value.
 *  Returning this value will cause the first onError block in registered observers to be called.
 *
 *  @param error Error describing cause of failure.
 *
 *  @return Dummy value.
 */
+ (instancetype) error:(NSError *)error;

@end

#ifdef REACTION_DEBUG

@interface NSObject (ReactionDebug)

/**
 *  Reaction which will run assynchronously on global async queue and return value.
 *  This value will be used as a response.
 *
 *  @param block Block which will return response value.
 *  @param name Name of the block. Will show up in Reaction logs.
 *
 *  @return Temporary value on which observers may subscribe.
 */
+ (instancetype)reactionWithBlock:(ReactionBlock)block withName:(NSString *)name;

/**
 *  Reaction which will run assynchronously on main queue and return value.
 *  This value will be used as a response.
 *
 *  @param block Block which will return response value.
 *  @param name Name of the block. Will show up in Reaction logs.
 *
 *  @return Temporary value on which observers may subscribe.
 */
+ (instancetype)reactionWithBlockOnMainQueue:(ReactionBlock)block withName:(NSString *)name;

/**
 *  Reaction which will run assynchronously on specified queue and return value.
 *  This value will be used as a response.
 *
 *  @param block Block which will return response value.
 *  @param name Name of the block. Will show up in Reaction logs.
 *  @param queue Dispatch queue in which block will be run.
 *
 *
 *  @return Temporary value on which observers may subscribe.
 */
+ (instancetype)reactionWithBlock:(ReactionBlock)block
                         withName:(NSString *)name
                          onQueue:(dispatch_queue_t)queue;

/**
 *  Notify observers, that reaction block failed to return value.
 *  Returning this value will cause the first onError block in registered observers to be called.
 *
 *  @param error Error describing cause of failure.
 *
 *  @return Dummy value.
 */
+ (instancetype) error:(NSError *)error;

@end

#endif//REACTION_DEBUG
