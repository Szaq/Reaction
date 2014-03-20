//
//  ReactionDebug.m
//  Reaction
//
//  Created by Lukasz Kwoska on 18/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#ifdef REACTION_DEBUG

static char *Adjectives[] = {"autumn", "hidden", "bitter", "misty", "silent", "empty", "dry",
                           "dark", "summer", "icy", "delicate", "quiet", "white", "cool", "spring",
                           "winter", "patient", "twilight", "dawn", "crimson", "wispy", "weathered",
                           "blue", "billowing", "broken", "cold", "damp", "falling", "frosty", "green",
                           "long", "late", "lingering", "bold", "little", "morning", "muddy", "old",
                           "red", "rough", "still", "small", "sparkling", "throbbing", "shy",
                           "wandering", "withered", "wild", "black", "young", "holy", "solitary",
                           "fragrant", "aged", "snowy", "proud", "floral", "restless", "divine",
                           "polished", "ancient", "purple", "lively", "nameless"};

static char *Nouns[] = {"waterfall", "river", "breeze", "moon", "rain", "wind", "sea",
                        "morning", "snow", "lake", "sunset", "pine", "shadow", "leaf", "dawn",
                        "glitter", "forest", "hill", "cloud", "meadow", "sun", "glade", "bird",
                        "brook", "butterfly", "bush", "dew", "dust", "field", "fire", "flower",
                        "firefly", "feather", "grass", "haze", "mountain", "night", "pond",
                        "darkness", "snowflake", "silence", "sound", "sky", "shape", "surf",
                        "thunder", "violet", "water", "wildflower", "wave", "water", "resonance",
                        "sun", "wood", "dream", "cherry", "tree", "fog", "frost", "voice", "paper",
                        "frog", "smoke", "star"};

NSString *REAGetBlockName(const char *file, NSInteger line) {
  if (line > 0) {
    return [NSString stringWithFormat:@"^{%@:%ld}",
            [[NSString stringWithUTF8String:file] lastPathComponent],
            (long)line];
  }
  
  return [NSString stringWithUTF8String:file];
}

NSString *REAGetFunkyName(id object){
  NSInteger objectIdx = (NSInteger)object;
  NSInteger adjectiveId = (objectIdx >> 4) % (sizeof(Adjectives) / sizeof(char*));
  NSInteger nounId = rand() % (sizeof(Nouns) / sizeof(char*));
  return [NSString stringWithFormat:@"%s %s", Adjectives[adjectiveId], Nouns[nounId]];
}

#endif//#ifdef REACTION_DEBUG