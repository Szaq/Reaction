//
//  ReactionDebug.h
//  Reaction
//
//  Created by Łukasz Kwoska on 17.03.2014.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#ifndef Reaction_ReactionDebug_h
#define Reaction_ReactionDebug_h

#ifdef REACTION_DEBUG

  #import "DDLog.h"

  #ifndef REACTION_LOG_LEVEL
    #define REACTION_LOG_LEVEL LOG_LEVEL_DEBUG
  #endif//REACTION_LOG_LEVEL

  ///Get description of block's location.
  NSString *REAGetBlockName(const char *file, NSInteger line);
  ///Get funky name for specified object
  NSString *REAGetFunkyName(id object);
  /**
   *  Reaction debug logs for block suffixed with this property will show file and line where this block is defined.
   */
  #define REACTION_BLOCK withName:REAGetBlockName(__FILE__, __LINE__)
  #define NAME_BLOCK(name) withName:name

/********************* Internal definitions ****************************/
  #define REACTION_BLOCK_DEF withName:(NSString *)name
  #define REACTION_BLOCK_FORWARD withName:name
  #define REACTION_BLOCK_FORWARD_UNNAMED withName:[block description]
  #define REACTION_BLOCK_FORWARD_WRAPPED withName:[NSString stringWithFormat:@"WRAPPED: %@",name]
  #define REACTION_SET_LOG_LEVEL static int ddLogLevel = REACTION_LOG_LEVEL
  #define REACTION_LOG_DEBUG DDLogDebug
  #define REACTION_LOG_INFO DDLogInfo
  #define REACTION_SETUP_OBSERVER observer.name = name;
#else
  #define REACTION_BLOCK
  #define NAME_BLOCK(name)

/********************* Internal definitions ****************************/
  #define REACTION_BLOCK_DEF
  #define REACTION_BLOCK_FORWARD
  #define REACTION_BLOCK_FORWARD_UNNAMED
  #define REACTION_BLOCK_FORWARD_WRAPPED
  #define REACTION_SET_LOG_LEVEL
  #define REACTION_LOG_DEBUG(frmt, ...)
  #define REACTION_LOG_INFO(frmt, ...)
  #define REACTION_SETUP_OBSERVER

#endif//REACTION_DEBUG

#endif
