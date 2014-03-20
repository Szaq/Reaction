//
//  NSObject+ReactionAsyncObject.h
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReactionAssociatedObject.h"

@interface NSObject (ReactionAssociatedObject)
///Get associated reaction object
- (ReactionAssociatedObject *)reactionObject;
///Get associated reaction object. Create it if neccessary.
- (ReactionAssociatedObject *)reactionObjectEnsureCreated;

///Get associated reaction error.
- (NSError *)reactionError;
///Set associated reaction error.
- (void)setReactionError:(NSError *)error;
@end

@interface NSProxy (ReactionAssociatedObject)
///Get associated reaction object
- (ReactionAssociatedObject *)reactionObject;
///Get associated reaction object. Create it if neccessary.
- (ReactionAssociatedObject *)reactionObjectEnsureCreated;

///Get associated reaction error.
- (NSError *)reactionError;
///Set associated reaction error.
- (void)setReactionError:(NSError *)error;
@end
