A simplified open source *Reactive Functional Programming* paradigm implementation.

# Introduction
You may think of this library as of lightweight version of ReactiveCocoa, or any other RFP library. This library is focused on providing fast and simple asynchronicity. As usually the best way to see what this library is capable of is by example.

Say you have some manager object with a possibly long-running method. Let's call this manager AManager and the method aLongRunningMethod.

```
#!objective-c

- (NSArray *)aLongRunningMethod {
}

```
and you want to take a value from it and use it in your UI. You may call it directly, but you know it may make your interface unresponsive, so you decide either on using GCD, or registering as delegate in AManager, or using NSNotificationCenter. It would be great if you could just get this value and be notified when it's ready. Let's try just that:

```
#!objective-c
//Somewhere in your UI code...
[[self.aManager aLongRunningMethod] observe:^(NSArray *object){
  //do something with this value.
  self.myArray = object;
  [self reloadData];
}];

```

Phef, that was easy. But certainly aLongRunningMethod's implementation must be complicated or contain some ugly voodoo macros. Let's check it:


```
#!objective-c
- (NSArray *)aLongRunningMethod {
  return [NSArray reactionWithBlock:^{
    //Some long running code returning our desired object
    return aGeneratedArray;
  }
}

```

Nothing simpler, than just returning block of code which will generate a return value.
Well..it may be simpler. Suppose we had this array already cached:
 
```
#!objective-c
- (NSArray *)aLongRunningMethod {
  if ([self isArrayCached])
    return aCachedArray;

  return [NSArray reactionWithBlock:^{
    //Some long running code returning our desired object
    return aGeneratedArray;
  }];
}

```

So when you already have needed value then there's no need to launch asynchronous task. It may be safely returned. Your observer will be called.

Suppose you want to change the value somehow before returning it to observer. Just call process.

```
#!objective-c

[[[self.aManager aLongRunningMethod]
 processAsync^id(NSArray *object){
    return [array arrayByFilteringSomehow];
 }
 observe:^(NSArray *object){
  //do something with this value.
  self.myArray = object;
  [self reloadData];
}];
```
This way an observer gets an array filtered in the global asynchronous dispatch queue.
```
#!objective-c

[[[self.aManager aLongRunningMethod]
 processAsync^id(NSArray *object){
    return [array arrayByFilteringSomehow];
 }
 observe:^(NSArray *object){
  //do something with this value.
  self.myArray = object;
  [self reloadData];
}];
```

Perhaps somewhere during processing error may occur. By creating OnError observer we can skip rest of observers but the first OnError.

```
#!objective-c

[[[[self.aManager aLongRunningMethod]
 processAsync^id(NSArray *object){
    return [array arrayByFilteringSomehow];
 }
 observe:^(NSArray *object){
  //do something with this value.
  self.myArray = object;
  [self reloadData];
}] 
onError:^(NSError *error) {
   NSLog(@"Error occurred : %@", error);
}];
```

We may generate error in two places. Either in aLongRunningMethod and in process. We generate error by returning [NSObject error:]. For example in aLongRunningMethod:

```
#!objective-c
- (NSArray *)aLongRunningMethod {
  if ([self isArrayCached])
    return aCachedArray;

  return [NSArray reactionWithBlock:^{
    if (someErrorCondition) {
        return [NSArray error:[NSError errorWithDomain:...]];
    }
    //Some long running code returning our desired object
    return aGeneratedArray;
  }];
}

```


Often we don't need result of some asynchronous operation. Just knowledge that it is done. We may use then.
```
#!objective-c

[[[self.aManager aLongRunningMethod]
 processAsync^id(NSArray *object){
    return [array arrayByFilteringSomehow];
 }
 then:^{
  //do something with this value.
}];
```
If our manager method doesn't return anything meaningful, then we may specify VoidReaction return type and return [VoidReaction Void]; Observers will receive nil.


We can observe directly on block or value.

```
#!objective-c

[[NSNumber reactionWithBlock:^id{ return @12; } observe ^(NSNumber *number){//Do something}];
```

or even:


```
#!objective-c

[@12 observeAsync ^(NSNumber *number){//Do something}];
```

#Installation
CocoaPods are being prepared. For now just Drag'n'Drop source folder into your project and remove ReactionTests.m from normal build target.

Then import headers.

```
#!objective-c
#import "NSObject+Reaction.h"
#import "NSObject+ReactionObservation.h"
```


#Debug Logs

Just specify REACTION_DEBUG (and possibly REACTION_FUNKY_NAMES) preprocessor macros in project settings or in code before importing Reaction headers. You may also define REACTION_LOG_LEVEL.

Make sure you have CocoaLumberjack set-up in your project for logging to work.


#Expected changes
Nothing in the API, but I will add possibility (ifdefed) to store last queue, so event after reaction and all observers finishes, xxxOnSameQueue is called in the same queue and not in main or async queue. Lack of support in current version is dictated by my primary tenet - speed and size. But i will solve it using macros.

#More
More is comming...

#Contribute
All contributions are welcome! :)
Due to my language and documenting skills currently the most needed contributions are documentations - both in code and on github. Just fork-change-pull request :)

If you have any question or suggestion, just drop me a mail at opensource (at) spinaldevelopment.com.