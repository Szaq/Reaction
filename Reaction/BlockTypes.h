//
//  BlockTypes.h
//  Reaction
//
//  Created by Lukasz Kwoska on 14/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#ifndef Reaction_BlockTypes_h
#define Reaction_BlockTypes_h

typedef dispatch_block_t ThenBlock;
typedef id(^ReactionBlock)();
typedef void(^ObserveBlock)(id);
typedef id(^ProcessBlock)(id);
typedef void(^OnErrorBlock)(NSError *);


#endif
