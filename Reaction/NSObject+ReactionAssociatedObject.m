//
//  NSObject+ReactionAsyncObject.m
//  Reaction
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//
#import <objc/runtime.h>
#import "NSObject+ReactionAssociatedObject.h"

static const char *ReactionAssociedObjectKey = "ReactionAssociedObjectKey";
static const char *ReactionErrorKey = "ReactionErrorObjectKey";

@implementation NSObject (ReactionAssociatedObject)
- (ReactionAssociatedObject *)reactionObject {
  return (ReactionAssociatedObject *)objc_getAssociatedObject(self, (void*)ReactionAssociedObjectKey);
}

- (ReactionAssociatedObject *)reactionObjectEnsureCreated {
  @synchronized(self) {
    ReactionAssociatedObject *object = [self reactionObject];
    if (!object) {
      object = [[ReactionAssociatedObject alloc] initWithObject:self];
      objc_setAssociatedObject(self, (void*)ReactionAssociedObjectKey, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return object;
  }
}

- (NSError *)reactionError {
  return (NSError *)objc_getAssociatedObject(self, (void*)ReactionErrorKey);
}

- (void)setReactionError:(NSError *)error {
  objc_setAssociatedObject(self, (void*)ReactionErrorKey, error, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@implementation NSProxy (ReactionAssociatedObject)
- (ReactionAssociatedObject *)reactionObject {
  return (ReactionAssociatedObject *)objc_getAssociatedObject(self, (void*)ReactionAssociedObjectKey);
}

- (ReactionAssociatedObject *)reactionObjectEnsureCreated {
  ReactionAssociatedObject *object = [self reactionObject];
  if (!object) {
    object = [[ReactionAssociatedObject alloc] init];
    objc_setAssociatedObject(self, (void*)ReactionAssociedObjectKey, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return object;
}

- (NSError *)reactionError {
  return (NSError *)objc_getAssociatedObject(self, (void*)ReactionErrorKey);
}

- (void)setReactionError:(NSError *)error {
  objc_setAssociatedObject(self, (void*)ReactionErrorKey, error, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
