//
//  VoidReaction.h
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * VoidReaction can be declared as a return type of methods returning reactions which result is not important.
 * Observers will receive null in their blocks if we return VoidReaction from methods returning reactions.
 */
@interface VoidReaction : NSObject
/**
 * void object for VoidReaction type.
 * @return Newly created void object.
 */
+ (VoidReaction *)Void;
@end
