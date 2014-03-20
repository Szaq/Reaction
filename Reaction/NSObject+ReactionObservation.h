//
//  NSObject+ReactionObservation.h
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlockTypes.h"
#import "ReactionDebug.h"

@interface NSObject (ReactionObservation)

/**
 *  Block will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Block will be executed in main dispatch queue.
 *
 *  @param block Block which will be executed.
 *
 *  @return Self.
 */
- (instancetype)then:(ThenBlock)block;

/**
 *  Block will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Block will be executed in the same queue as reaction or previous observer.
 *  In case of immediate value, observer will run in main queue.
 *  If reaction finishes before this block is added
 *  than it's return value is treated as an immediate value.
 *
 *  @param block Block which will be executed.
 *
 *  @return Self.
 */
- (instancetype)thenOnSameQueue:(ThenBlock)block;

/**
 *  Block will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Block will be executed in global async dispatch queue with default priority.
 *
 *  @param block Block which will be executed.
 *
 *  @return Self.
 */
- (instancetype)thenAsync:(ThenBlock)block;

/**
 *  Block will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Block will be executed in specified queue.
 *
 *  @param block Block which will be executed.
 *  @param queue Queue in which block is to be executed.
 *
 *  @return Self.
 */
- (instancetype)then:(ThenBlock)block onQueue:(dispatch_queue_t)queue;

/**
 *  Block receives returned object and will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Block will be executed in main dispatch queue.
 *
 *  @param block Block which will be executed.
 *
 *  @return Self.
 */
- (instancetype)observe:(ObserveBlock)block;

/**
 *  Block receives returned object and will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Block will be executed in the same queue as reaction or previous observer.
 *  In case of immediate value, observer will run in main queue. If reaction finishes before this block is added
 *  than it's return value is treated as an immediate value.
 *
 *  @param block Block which will be executed.
 *
 *  @return Self.
 */
- (instancetype)observeOnSameQueue:(ObserveBlock)block;

/**
 *  Block receives returned object and will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Block will be executed in global async dispatch queue with default priority.
 *
 *  @param block Block which will be executed.
 *
 *  @return Self.
 */

- (instancetype)observeAsync:(ObserveBlock)block;

/**
 *  Block receives returned object and will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Block will be executed in specified queue.
 *
 *  @param block Block which will be executed.
 *  @param queue Queue in which block is to be executed.
 *
 *  @return Self.
 */
- (instancetype)observe:(ObserveBlock)block onQueue:(dispatch_queue_t)queue;

/**
 *  Block receives object returned from reaction and returns new one.
 *  Next registered observers will receive value returned
 *  from this block. Block may return error. @see [NSObject error:].
 *  Block will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Processing will be executed in the same thread as oryginal value generation, or previous observer if process
 *  is not first observer.
 *  In case of immediate value, observer will run in global async queue with default priority.
 *  If reaction finishes before this block is added
 *  than it's return value is treated as an immediate value.
 *
 *
 *  @param block Block which will be used to process value.
 *
 *  @return Self.
 */
- (instancetype)process:(id(^)(id))block;

/**
 *  Block receives object returned from reaction and returns new one.
 *  Next registered observers will receive value returned
 *  from this block. Block may return error. @see [NSObject error:].
 *  Block will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Processing will be executed in the main queue.
 *
 *  @param block Block which will be used to process value.
 *
 *  @return Self.
 */
- (instancetype)processOnMainQueue:(id(^)(id))block;

/**
 *  Block receives object returned from reaction and returns new one.
 *  Next registered observers will receive value returned
 *  from this block. Block may return error. @see [NSObject error:].
 *  Block will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Processing will be executed in global async dispatch queue with default priority.
 *
 *  @param block Block which will be used to process value.
 *
 *  @return Self.
 */
- (instancetype)processAsync:(id(^)(id))block;

/**
 *  Block receives object returned from reaction and returns new one.
 *  Next registered observers will receive value returned
 *  from this block. Block may return error. @see [NSObject error:].
 *  Block will be executed when value of an object on which user observes
 *  is returned. Possibly right-away, but it may happen after some time.
 *  Processing will be executed in the specified queue.
 *
 *  @param block Block which will be used to process value.
 *  @param queue Queue in which to launch block.
 *
 *  @return Self.
 */
- (instancetype)process:(id(^)(id))block onQueue:(dispatch_queue_t)queue;

/**
 *  Block catches an error returned from reactions and process observers and will be executed
 *  when error is returned. Possibly right-away, but it may happen after some time.
 *  If an error is returned from reaction or process observer than first OnError observer is launched,
 *  and other observers are canceled - also subsequent OnErrors.
 *  Block will be executed in main dispatch queue.
 *
 *  @param block Block which will be executed.
 *
 *  @return Self.
 */
- (instancetype)onError:(void(^)(NSError *))block;

/**
 *  Block catches an error returned from reactions and process observers and will be executed
 *  when error is returned. Possibly right-away, but it may happen after some time.
 *  If an error is returned from reaction or process observer than first OnError observer is launched,
 *  and other observers are canceled - also subsequent OnErrors.
 *  Block will be executed in the same queue as reaction or previous observer.
 *  In case of immediate value, observer will run in main queue.
 *
 *  @param block Block which will be executed.
 *
 *  @return Self.
 */
- (instancetype)onErrorOnSameQueue:(void(^)(NSError *))block;

/**
 *  Block catches an error returned from reactions and process observers and will be executed
 *  when error is returned. Possibly right-away, but it may happen after some time.
 *  If an error is returned from reaction or process observer than first OnError observer is launched,
 *  and other observers are canceled - also subsequent OnErrors.
 *  Block will be executed in main dispatch queue.
 *
 *  @param block Block which will be executed in global async dispatch queue with default priority.
 *
 *  @return Self.
 */
- (instancetype)onErrorAsync:(void(^)(NSError *))block;

/**
 *  Block catches an error returned from reactions and process observers and will be executed
 *  when error is returned. Possibly right-away, but it may happen after some time.
 *  If an error is returned from reaction or process observer than first OnError observer is launched,
 *  and other observers are canceled - also subsequent OnErrors.
 *  Block will be executed in specified queue.
 *
 *  @param block Block which will be executed in global async dispatch queue with default priority.
 *  @param queue Dispatch queue in which block will be executed.
 *
 *  @return Self.
 */
- (instancetype)onError:(void(^)(NSError *))block onQueue:(dispatch_queue_t)queue;

/**
 *  Remove all observers which hasn't yet launched.
 */
- (void)cancelAllObservers;

@end

#ifdef REACTION_DEBUG

@interface NSObject (ReactionObservationDebug)

- (instancetype)then:(ThenBlock)block withName:(NSString *)name;
- (instancetype)thenOnSameQueue:(ThenBlock)block withName:(NSString *)name;
- (instancetype)thenAsync:(ThenBlock)block withName:(NSString *)name;
- (instancetype)then:(ThenBlock)block withName:(NSString *)name onQueue:(dispatch_queue_t)queue;
- (instancetype)observe:(ObserveBlock)block withName:(NSString *)name;
- (instancetype)observeOnSameQueue:(ObserveBlock)block withName:(NSString *)name;
- (instancetype)observeAsync:(ObserveBlock)block withName:(NSString *)name;
- (instancetype)observe:(ObserveBlock)block withName:(NSString *)name onQueue:(dispatch_queue_t)queue;
- (instancetype)process:(id(^)(id))block withName:(NSString *)name;
- (instancetype)processOnMainQueue:(id(^)(id))block withName:(NSString *)name;
- (instancetype)processAsync:(id(^)(id))block withName:(NSString *)name;
- (instancetype)process:(id(^)(id))block withName:(NSString *)name onQueue:(dispatch_queue_t)queue;
- (instancetype)onError:(void(^)(NSError *))block withName:(NSString *)name;
- (instancetype)onErrorOnSameQueue:(void(^)(NSError *))block withName:(NSString *)name;
- (instancetype)onErrorAsync:(void(^)(NSError *))block withName:(NSString *)name;
- (instancetype)onError:(void(^)(NSError *))block withName:(NSString *)name onQueue:(dispatch_queue_t)queue;

@end

#endif//REACTIONDEBUG
