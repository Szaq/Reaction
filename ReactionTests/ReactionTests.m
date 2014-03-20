//
//  ReactionTests.m
//  ReactionTests
//
//  Created by Lukasz Kwoska on 13/03/14.
//  Copyright (c) 2014 Spinal Development. All rights reserved.
//

#import <XCTest/XCTest.h>
#ifdef REACTION_DEBUG
  #import "DDLog.h"
  #import "DDTTYLogger.h"
#endif

#import "NSObject+Reaction.h"
#import "NSObject+ReactionObservation.h"
#import "ReactionAssociatedObject.h"

#import "TestSemaphore.h"

static const char *CurrentQueueKey = "CurrentKey";

@interface ReactionTests : XCTestCase
@property dispatch_queue_t mainQueueSubstitute;
@property dispatch_queue_t alternativeQueue;
@end

@implementation ReactionTests

- (void)setUp
{
  [super setUp];
#ifdef REACTION_DEBUG
  [DDLog removeAllLoggers];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
  
  self.mainQueueSubstitute = dispatch_queue_create("Main Queue Substitute", NULL);
  self.alternativeQueue = dispatch_queue_create("Alternative Queue", NULL);
  
  [ReactionAssociatedObject setMainQueueSubstituteQueue:self.mainQueueSubstitute];
  
  dispatch_queue_set_specific(self.mainQueueSubstitute,
                              (void*)CurrentQueueKey,
                              (__bridge void*)self.mainQueueSubstitute,
                              NULL);
  dispatch_queue_set_specific(self.alternativeQueue,
                              (void*)CurrentQueueKey,
                              (__bridge void*)self.alternativeQueue,
                              NULL);
  
  dispatch_queue_t asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_queue_set_specific(asyncQueue,
                              (void*)CurrentQueueKey,
                              (__bridge void*)asyncQueue,
                              NULL);
}

- (void)tearDown
{
  [ReactionAssociatedObject setMainQueueSubstituteQueue:nil];
  [super tearDown];
}

- (NSNumber *)generateNumberAsync:(BOOL)async withSemaphoreName:(NSString *)semaphoreName {
  if (async) {
    return [NSNumber reactionWithBlock:^id{
      [NSThread sleepForTimeInterval:(10 + rand() % 100) / 1000];
      if (semaphoreName) {
        [[TestSemaphore sharedInstance] lift:semaphoreName];
      }
      return @(rand());
    }];
  }
  
  if (semaphoreName) {
    [[TestSemaphore sharedInstance] lift:semaphoreName];
  }
  return @(rand());
}

- (void)testSimpleThenSync {
  
  [[[[self generateNumberAsync:NO withSemaphoreName:@"testSimpleThenSync"] then:^{
    [[TestSemaphore sharedInstance] lift:@"testSimpleThenSync THEN"];
  } REACTION_BLOCK]
  then:^{
    [[TestSemaphore sharedInstance] lift:@"testSimpleThenSync THEN2"];
  } REACTION_BLOCK]
  observe:^(id param) {
    [[TestSemaphore sharedInstance] lift:@"testSimpleThenSync OBSERVE"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenSync"];
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenSync THEN"];
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenSync THEN2"];
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenSync OBSERVE"];
}

- (void)testSimpleThenAsync {
  
  [[[[self generateNumberAsync:YES withSemaphoreName:@"testSimpleThenAsync"] then:^{
    [[TestSemaphore sharedInstance] lift:@"testSimpleThenAsync THEN"];
  } REACTION_BLOCK]
    then:^{
      [[TestSemaphore sharedInstance] lift:@"testSimpleThenAsync THEN2"];
    } REACTION_BLOCK]
   observe:^(id param) {
     [[TestSemaphore sharedInstance] lift:@"testSimpleThenAsync OBSERVE"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenAsync"];
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenAsync THEN"];
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenAsync THEN2"];
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenAsync OBSERVE"];
}

- (void)testOrderSimpleThenAsync {
  __block BOOL firstThenCalled = NO;
  __block BOOL secondThenCalled = NO;
  __block BOOL observeCalled = NO;
  
  [[[[self generateNumberAsync:YES withSemaphoreName:@"testSimpleThenAsync"] then:^{
    XCTAssertEqual(firstThenCalled, NO, @"Wrong order First then should be called only once.");
    XCTAssertEqual(secondThenCalled, NO, @"Wrong order First then should be called first.");
    XCTAssertEqual(observeCalled, NO, @"Wrong order First then should be called first.");

    firstThenCalled = YES;
  } REACTION_BLOCK]
    then:^{
      XCTAssertEqual(firstThenCalled, YES, @"Wrong order First then should be already be called.");
      XCTAssertEqual(secondThenCalled, NO, @"Wrong order Second then should be called only once.");
      XCTAssertEqual(observeCalled, NO, @"Wrong order Second then should be called second.");

      secondThenCalled = YES;
    } REACTION_BLOCK]
   observe:^(id param) {
     XCTAssertEqual(firstThenCalled, YES, @"Wrong order First then should be already be called.");
     XCTAssertEqual(secondThenCalled, YES, @"Wrong order Second then should be already be called.");
     XCTAssertEqual(observeCalled, NO, @"Wrong order Observe should be called seonly oncecond.");
     
     observeCalled = YES;
     
     [[TestSemaphore sharedInstance] lift:@"testSimpleThenAsync OBSERVE"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testSimpleThenAsync OBSERVE"];
  XCTAssertEqual(firstThenCalled & secondThenCalled & observeCalled, 1, @"All observers should be called");
}

- (void)testOrderSimpleThenSync {
  __block BOOL firstThenCalled = NO;
  __block BOOL secondThenCalled = NO;
  __block BOOL observeCalled = NO;
  
  [[[[self generateNumberAsync:NO withSemaphoreName:@"testOrderSimpleThenSync"] then:^{
    XCTAssertEqual(firstThenCalled, NO, @"Wrong order First then should be called only once.");
    XCTAssertEqual(secondThenCalled, NO, @"Wrong order First then should be called first.");
    XCTAssertEqual(observeCalled, NO, @"Wrong order First then should be called first.");
    
    firstThenCalled = YES;
  } REACTION_BLOCK]
    then:^{
      XCTAssertEqual(firstThenCalled, YES, @"Wrong order First then should be already be called.");
      XCTAssertEqual(secondThenCalled, NO, @"Wrong order Second then should be called only once.");
      XCTAssertEqual(observeCalled, NO, @"Wrong order Second then should be called second.");
      
      secondThenCalled = YES;
    } REACTION_BLOCK]
   observe:^(id param) {
     XCTAssertEqual(firstThenCalled, YES, @"Wrong order First then should be already be called.");
     XCTAssertEqual(secondThenCalled, YES, @"Wrong order Second then should be already be called.");
     XCTAssertEqual(observeCalled, NO, @"Wrong order Observe should be called seonly oncecond.");
     
     observeCalled = YES;
     
     [[TestSemaphore sharedInstance] lift:@"testOrderSimpleThenSync OBSERVE"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testOrderSimpleThenSync OBSERVE"];
  
  XCTAssertEqual(firstThenCalled, YES, @"Wrong order First then should be already be called.");
  XCTAssertEqual(secondThenCalled, YES, @"Wrong order Second then should be already be called.");
  XCTAssertEqual(observeCalled, YES, @"Wrong order Observe should be called seonly oncecond.");
}

- (NSObject *)getObject:(NSObject *)object async:(BOOL)async {
  if (async) {
    return [NSObject reactionWithBlock:^id{
      return object;
    } REACTION_BLOCK];
  }
  
  return object;
}

- (void)testObservesGetRightObjectSync {
  __block BOOL observeGotRightValue = YES;
  
  NSString *testString = [NSString stringWithFormat:@"Test string %@", self];
  [[[[[self getObject:testString async:NO] observe:^(NSString *object) {
    observeGotRightValue &= (testString == object);
  } REACTION_BLOCK]
  observeAsync:^(NSString *object) {
    observeGotRightValue &= (testString == object);
  } REACTION_BLOCK]
  observeOnSameQueue:^(NSString *object) {
    observeGotRightValue &= (testString == object);
  } REACTION_BLOCK]
  observe:^(NSString *object) {
  observeGotRightValue &= (testString == object);
    [[TestSemaphore sharedInstance] lift:@"testObservesGetRightObjectSync"];
  } REACTION_BLOCK
   onQueue:self.mainQueueSubstitute];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testObservesGetRightObjectSync"];
  XCTAssertTrue(observeGotRightValue, @"Observe didn't get original value");
}

- (void)testObservesGetRightObjectAsync {
  NSString *testString = [NSString stringWithFormat:@"Test string %@", self];
  [[[[[self getObject:testString async:YES]
      observe:^(NSString *object) {
        XCTAssertEqual(testString, object, @"Observe didn't get original value");
      } REACTION_BLOCK]
     observeAsync:^(NSString *object) {
       XCTAssertEqual(testString, object, @"Observe didn't get original value");
     } REACTION_BLOCK]
    observeOnSameQueue:^(NSString *object) {
      XCTAssertEqual(testString, object, @"Observe didn't get original value");
    } REACTION_BLOCK]
   observe:^(NSString *object) {
     XCTAssertEqual(testString, object, @"Observe didn't get original value");
     [[TestSemaphore sharedInstance] lift:@"testObservesGetRightObjectAsync"];
   } REACTION_BLOCK
   onQueue:self.mainQueueSubstitute];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testObservesGetRightObjectAsync"];
}

- (void)testProcessingsGetAndSetRightObjectSync {
  NSString *testString = [NSString stringWithFormat:@"Test string %@", self];
  [[[[[self getObject:testString async:NO]
      observe:^(NSString *object) {
        XCTAssertEqual(testString, object, @"Observe didn't get original value");
      } REACTION_BLOCK]
     observeAsync:^(NSString *object) {
       XCTAssertEqual(testString, object, @"Observe didn't get original value");
     } REACTION_BLOCK]
    observeOnSameQueue:^(NSString *object) {
      XCTAssertEqual(testString, object, @"Observe didn't get original value");
    } REACTION_BLOCK]
   observe:^(NSString *object) {
     XCTAssertEqual(testString, object, @"Observe didn't get original value");
     [[TestSemaphore sharedInstance] lift:@"testProcessingsGetAndSetRightObjectSync"];
   } REACTION_BLOCK
   onQueue:self.mainQueueSubstitute];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testProcessingsGetAndSetRightObjectSync"];
}

- (void)testProcessingsGetAndSetRightObjectAsync {
  NSString *testString = [NSString stringWithFormat:@"Test string %@", self];
  NSNumber *testNumber = @(rand());
  NSArray *testArray = @[testString, testNumber];
  NSDictionary *testDict = @{@"testArray" : testArray};
  
  [[[[[self getObject:testString async:YES]
      process:(id)^(NSString *object) {
        XCTAssertEqual(testString, object, @"Observe didn't get original value");
        return testNumber;
      } REACTION_BLOCK]
     processAsync:(id)^(NSNumber *object) {
       XCTAssertEqual(testNumber, object, @"Observe didn't get original value");
       return testArray;
     } REACTION_BLOCK]
    processOnMainQueue:(id)^(NSArray *object) {
      XCTAssertEqual(testArray, object, @"Observe didn't get original value");
      return testDict;
    } REACTION_BLOCK]
   process:(id)^(NSDictionary *object) {
     XCTAssertEqual(testDict, object, @"Observe didn't get original value");
     [[TestSemaphore sharedInstance] lift:@"testProcessingsGetAndSetRightObjectAsync"];
   } REACTION_BLOCK
   onQueue:self.mainQueueSubstitute];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testProcessingsGetAndSetRightObjectAsync"];
}

- (NSString *)getErrorAsync:(BOOL)async {
  NSString *error = [NSString error:[NSError errorWithDomain:@"TestDomain" code:123 userInfo:nil]];
  if (async) {
    return [NSString reactionWithBlock:^id{
      return error;
    }];
  }
  return error;
}

- (void)testErrorCallsOnErrorAndSkipsAllPreviousObserversAsync {
  __block BOOL onErrorCalled = NO;
  [[[[[self getErrorAsync:YES]
   then:^{
     XCTFail(@"'Then; shouldn't have been called.");
  } REACTION_BLOCK]
  process:^id(id object) {
    XCTFail(@"'Process' shouldn't have been called.");
    return nil;
  } REACTION_BLOCK]
  observe:^(id object) {
    XCTFail(@"'Observe' shouldn't have been called.");
  } REACTION_BLOCK]
  onError:^(NSError *error) {
    onErrorCalled = YES;
    [[TestSemaphore sharedInstance] lift:@"testErrorCallsOnErrorAndSkipsAllPreviousObserversAsync"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testErrorCallsOnErrorAndSkipsAllPreviousObserversAsync"];
  XCTAssertTrue(onErrorCalled, @"OnError wasn't called");
}

- (void)testErrorCallsOnErrorAndSkipsAllPreviousObserversSync {
  __block BOOL onErrorCalled = NO;
  [[[[[self getErrorAsync:NO]
      then:^{
        XCTFail(@"'Then; shouldn't have been called.");
      } REACTION_BLOCK]
     process:^id(id object) {
       XCTFail(@"'Process' shouldn't have been called.");
       return nil;
     } REACTION_BLOCK]
    observe:^(id object) {
      XCTFail(@"'Observe' shouldn't have been called.");
    } REACTION_BLOCK]
   onError:^(NSError *error) {
     onErrorCalled = YES;
     [[TestSemaphore sharedInstance] lift:@"testErrorCallsOnErrorAndSkipsAllPreviousObserversSync"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testErrorCallsOnErrorAndSkipsAllPreviousObserversSync"];
  XCTAssertTrue(onErrorCalled, @"OnError wasn't called");
}

- (void)testErrorCancelsAllNextObserversAsync {
  [[[[[[self getErrorAsync:YES]
  onError:^(NSError *error) {
    [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversAsync"];
  } REACTION_BLOCK]
     then:^{
       [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversAsyncFAIL"];
       XCTFail(@"'Then; shouldn't have been called.");
     } REACTION_BLOCK]
    process:^id(id object) {
      [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversAsyncFAIL"];
      XCTFail(@"'Process' shouldn't have been called.");
      return nil;
    } REACTION_BLOCK]
   observe:^(id object) {
     [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversAsyncFAIL"];
     XCTFail(@"'Observe' shouldn't have been called.");
   } REACTION_BLOCK]
   onError:^(NSError *error) {
     XCTFail(@"Second 'OnError' shouldn't have been called.");
     [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversAsyncFAIL"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testErrorCancelsAllNextObserversAsync"];
  //Aditional time for possible other methods
  [[TestSemaphore sharedInstance] waitForKey:@"testErrorCancelsAllNextObserversAsyncFAIL" timeout:2];
}

- (void)testErrorCancelsAllNextObserversSync {
  [[[[[[self getErrorAsync:NO]
       onError:^(NSError *error) {
         [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversSync"];
       } REACTION_BLOCK]
      then:^{
        [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversSyncFAIL"];
        XCTFail(@"'Then; shouldn't have been called.");
      } REACTION_BLOCK]
     process:^id(id object) {
       [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversSyncFAIL"];
       XCTFail(@"'Process' shouldn't have been called.");
       return nil;
     } REACTION_BLOCK]
    observe:^(id object) {
      [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversSyncFAIL"];
      XCTFail(@"'Observe' shouldn't have been called.");
    } REACTION_BLOCK]
   onError:^(NSError *error) {
     XCTFail(@"Second 'OnError' shouldn't have been called.");
     [[TestSemaphore sharedInstance] lift:@"testErrorCancelsAllNextObserversAsyncFAIL"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testErrorCancelsAllNextObserversSync"];
  //Aditional time for possible other methods
  [[TestSemaphore sharedInstance] waitForKey:@"testErrorCancelsAllNextObserversAsyncFAIL" timeout:2];
}

- (void)testErrorGeneratedFromProcessObserverAsync {
  __block BOOL onErrorCallled = NO;
  [[[[[self generateNumberAsync:YES withSemaphoreName:nil]
   onError:^(NSError *error) {
     XCTFail(@"First onError shouldn't be called.");
  } REACTION_BLOCK]
  process:^id(id object) {
    return [NSNumber error:[NSError errorWithDomain:@"Sample error" code:122 userInfo:nil]];
  } REACTION_BLOCK]
  onError:^(NSError *error) {
    onErrorCallled = YES;
    [[TestSemaphore sharedInstance] lift:@"testErrorGeneratedFromProcessObserverAsync"];
  } REACTION_BLOCK]
  then:^{
    XCTFail(@"This then should have been canceled.");
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testErrorGeneratedFromProcessObserverAsync" timeout:2];
}

- (void)testErrorGeneratedFromProcessObserverSync {
  __block BOOL onErrorCallled = NO;
  [[[[[self generateNumberAsync:NO withSemaphoreName:nil]
     onError:^(NSError *error) {
       XCTFail(@"First onError shouldn't be called.");
     } REACTION_BLOCK]
    process:^id(id object) {
      return [NSNumber error:[NSError errorWithDomain:@"Sample error" code:121 userInfo:nil]];
    } REACTION_BLOCK]
   onError:^(NSError *error) {
     onErrorCallled = YES;
     [[TestSemaphore sharedInstance] lift:@"testErrorGeneratedFromProcessObserverAsync"];
   } REACTION_BLOCK]
  then:^{
    XCTFail(@"This then should have been canceled.");
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testErrorGeneratedFromProcessObserverAsync" timeout:2];
}

#define assertIfNotOnMainQueue() \
  XCTAssertEqual(self.mainQueueSubstitute, (__bridge dispatch_queue_t)dispatch_get_specific((void *)CurrentQueueKey), \
                 @"Reaction executed on thread other than main.");

#define assertIfNotOnAsyncQueue() \
  XCTAssertEqual(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), \
                 (__bridge dispatch_queue_t)dispatch_get_specific((void *)CurrentQueueKey), \
                 @"Reaction executed on thread other than asynchronous.");

#define assertIfNotOnAlternativeQueue() \
  XCTAssertEqual(self.alternativeQueue, (__bridge dispatch_queue_t)dispatch_get_specific((void *)CurrentQueueKey), \
                 @"Reaction executed on thread other than specified one.");

- (void)testReactionsAreCalledInRightQueues {
  //Async queue
    [NSObject reactionWithBlock:^id{
      assertIfNotOnAsyncQueue();
      [[TestSemaphore sharedInstance] lift:@"testReactionsAreCalledInRightQueuesASYNC"];
    return nil;
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testReactionsAreCalledInRightQueuesASYNC"];
  
  
  //Main queue
  [NSObject reactionWithBlockOnMainQueue:^id{
    assertIfNotOnMainQueue();
    [[TestSemaphore sharedInstance] lift:@"testReactionsAreCalledInRightQueuesMAIN"];
    return nil;
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testReactionsAreCalledInRightQueuesMAIN"];
  
  
  //Specified queue
  [NSObject reactionWithBlock:^id{
    assertIfNotOnAlternativeQueue();
    [[TestSemaphore sharedInstance] lift:@"testReactionsAreCalledInRightQueuesSPECIFIED"];
    return nil;
  } REACTION_BLOCK
                      onQueue:self.alternativeQueue];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testReactionsAreCalledInRightQueuesSPECIFIED"];
}

- (void)testObservesAreCalledInRighQueues {
  [[[[[self generateNumberAsync:YES withSemaphoreName:nil]
      observeOnSameQueue:^(id value) { assertIfNotOnAsyncQueue(); } REACTION_BLOCK]
     observe:^(id value) { assertIfNotOnMainQueue(); } REACTION_BLOCK]
    observe:^(id value) { assertIfNotOnAlternativeQueue(); } REACTION_BLOCK onQueue:self.alternativeQueue]
   observeAsync:^(id value) {
     assertIfNotOnAsyncQueue();
     [[TestSemaphore sharedInstance] lift:@"testObservesAreCalledInRighQueuesASYNC"];
   } REACTION_BLOCK];
  [[TestSemaphore sharedInstance] waitForKey:@"testObservesAreCalledInRighQueuesASYNC"];
  
  [[[[[self generateNumberAsync:NO withSemaphoreName:nil]
      observeOnSameQueue:^(id value) {
        assertIfNotOnMainQueue();
      } REACTION_BLOCK]
     observe:^(id value) { assertIfNotOnMainQueue(); } REACTION_BLOCK]

    observe:^(id value) { assertIfNotOnAlternativeQueue(); } REACTION_BLOCK onQueue:self.alternativeQueue]
   observeAsync:^(id value) {
     assertIfNotOnAsyncQueue();
     [[TestSemaphore sharedInstance] lift:@"testObservesAreCalledInRighQueuesSYNC"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testObservesAreCalledInRighQueuesSYNC"];
}

-  (void) testThensOnSameQueues {
  //Async queue
  [[NSObject reactionWithBlock:^id{
    return nil;
  } REACTION_BLOCK] thenOnSameQueue:^{
    assertIfNotOnAsyncQueue();
    [[TestSemaphore sharedInstance] lift:@"testThensOnSameQueuesASYNC"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testThensOnSameQueuesASYNC"];
  
  //Main queue
  [[NSObject reactionWithBlockOnMainQueue:^id{
    return nil;
  } REACTION_BLOCK] thenOnSameQueue:^{
    assertIfNotOnMainQueue();
    [[TestSemaphore sharedInstance] lift:@"testThensOnSameQueuesMAIN"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testThensOnSameQueuesMAIN"];
  
  //Specified queue
  [[NSObject reactionWithBlock:^id{
    return nil;
  } REACTION_BLOCK
                       onQueue:self.alternativeQueue]
  thenOnSameQueue:^{
    assertIfNotOnAlternativeQueue();
    [[TestSemaphore sharedInstance] lift:@"testThensOnSameQueuesSPECIFIED"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testThensOnSameQueuesSPECIFIED"];
}

-  (void) testObservesOnSameQueues {
  //Async queue
  [[NSObject reactionWithBlock:^id{
    return nil;
  } REACTION_BLOCK] observeOnSameQueue:^(id value){
    assertIfNotOnAsyncQueue();
    [[TestSemaphore sharedInstance] lift:@"testObservesOnSameQueuesASYNC"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testObservesOnSameQueuesASYNC"];
  
  //Main queue
  [[NSObject reactionWithBlockOnMainQueue:^id{
    return nil;
  } REACTION_BLOCK] observeOnSameQueue:^(id value) {
    assertIfNotOnMainQueue();
    [[TestSemaphore sharedInstance] lift:@"testObservesOnSameQueuesMAIN"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testObservesOnSameQueuesMAIN"];
  
  //Specified queue
  [[NSObject reactionWithBlock:^id{
    return nil;
  }
                       onQueue:self.alternativeQueue]
   observeOnSameQueue:^(id value) {
     assertIfNotOnAlternativeQueue();
     [[TestSemaphore sharedInstance] lift:@"testObservesOnSameQueuesSPECIFIED"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testObservesOnSameQueuesSPECIFIED"];
}

-  (void) testProcessesOnSameQueues {
  //Async queue
  [[NSObject reactionWithBlock:^id{
    return nil;
  } REACTION_BLOCK] process:(id)^(id value) {
    assertIfNotOnAsyncQueue();
    [[TestSemaphore sharedInstance] lift:@"testProcessesOnSameQueuesASYNC"];
    return nil;
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testProcessesOnSameQueuesASYNC"];
  
  //Main queue
  [[NSObject reactionWithBlockOnMainQueue:^id{
    return nil;
  } REACTION_BLOCK] process:(id)^(id value) {
    assertIfNotOnMainQueue();
    [[TestSemaphore sharedInstance] lift:@"testProcessesOnSameQueuesMAIN"];
    return nil;
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testProcessesOnSameQueuesMAIN"];
  
  //Specified queue
  [[NSObject reactionWithBlock:^id{
    return nil;
  }
                       onQueue:self.alternativeQueue]
   process:(id)^(id value) {
     assertIfNotOnAlternativeQueue();
     [[TestSemaphore sharedInstance] lift:@"testProcessesOnSameQueuesSPECIFIED"];
     return nil;
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testProcessesOnSameQueuesSPECIFIED"];
}

-  (void) testOnErrorsOnSameQueues {
  //Async queue
  [[NSObject reactionWithBlock:^id{
    return [NSObject error:[NSError errorWithDomain:@"Sample error" code:124 userInfo:nil]];
  } REACTION_BLOCK] onErrorOnSameQueue:^(NSError *value){
    assertIfNotOnAsyncQueue();
    [[TestSemaphore sharedInstance] lift:@"testOnErrorsOnSameQueuesASYNC"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testOnErrorsOnSameQueuesASYNC"];
  
  //Main queue
  [[NSObject reactionWithBlockOnMainQueue:^id{
    return [NSObject error:[NSError errorWithDomain:@"Sample error" code:124 userInfo:nil]];
  } REACTION_BLOCK] onErrorOnSameQueue:^(NSError *value){
    assertIfNotOnMainQueue();
    [[TestSemaphore sharedInstance] lift:@"testOnErrorsOnSameQueuesMAIN"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testOnErrorsOnSameQueuesMAIN"];
  
  //Specified queue
  [[NSObject reactionWithBlock:^id{
    return [NSObject error:[NSError errorWithDomain:@"Sample error" code:124 userInfo:nil]];
  }
                       onQueue:self.alternativeQueue]
   onErrorOnSameQueue:^(NSError *value){
     assertIfNotOnAlternativeQueue();
     [[TestSemaphore sharedInstance] lift:@"testOnErrorsOnSameQueuesSPECIFIED"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testOnErrorsOnSameQueuesSPECIFIED"];
}


- (void)testProcessesAreCalledInRighQueues {
  [[[[[self generateNumberAsync:YES withSemaphoreName:nil]
      process:(id)^(id value) { assertIfNotOnAsyncQueue();return nil;} REACTION_BLOCK]
     processOnMainQueue:(id)^(id value) { assertIfNotOnMainQueue(); return nil;} REACTION_BLOCK]
    process:(id)^(id value) { assertIfNotOnAlternativeQueue(); return nil;} REACTION_BLOCK onQueue:self.alternativeQueue]
   processAsync:(id)^(id value) {
     assertIfNotOnAsyncQueue();
     [[TestSemaphore sharedInstance] lift:@"testProcessesAreCalledInRighQueuesASYNC"];
     return nil;
   } REACTION_BLOCK];
  [[TestSemaphore sharedInstance] waitForKey:@"testProcessesAreCalledInRighQueuesASYNC"];
  
  [[[[[self generateNumberAsync:NO withSemaphoreName:nil]
      process:(id)^(id value) { assertIfNotOnAsyncQueue(); return nil;} REACTION_BLOCK]
     processOnMainQueue:(id)^(id value) { assertIfNotOnMainQueue(); return nil;} REACTION_BLOCK]
    process:(id)^(id value) { assertIfNotOnAlternativeQueue(); return nil;} REACTION_BLOCK onQueue:self.alternativeQueue]
   processAsync:(id)^(id value) {
     assertIfNotOnAsyncQueue();
     [[TestSemaphore sharedInstance] lift:@"testProcessesAreCalledInRighQueuesSYNC"];
     return nil;
   } REACTION_BLOCK];
  [[TestSemaphore sharedInstance] waitForKey:@"testProcessesAreCalledInRighQueuesSYNC"];
}

- (void)testOnErrorsAreCalledInRightQueues {
  //Async queue
  [[NSObject reactionWithBlock:^id{
    return [NSObject error:[NSError errorWithDomain:@"Sample error" code:124 userInfo:nil]];
  } REACTION_BLOCK] onErrorOnSameQueue:^(NSError *value){
    assertIfNotOnAsyncQueue();
    [[TestSemaphore sharedInstance] lift:@"testOnErrorsAreCalledInRightQueuesASYNC"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testOnErrorsAreCalledInRightQueuesASYNC"];
  
  //Main queue
  [[NSObject reactionWithBlockOnMainQueue:^id{
    return [NSObject error:[NSError errorWithDomain:@"Sample error" code:124 userInfo:nil]];
  } REACTION_BLOCK] onErrorOnSameQueue:^(NSError *value){
    assertIfNotOnMainQueue();
    [[TestSemaphore sharedInstance] lift:@"testOnErrorsAreCalledInRightQueuesMAIN"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testOnErrorsAreCalledInRightQueuesMAIN"];
  
  //Specified queue
  [[NSObject reactionWithBlock:^id{
    return [NSObject error:[NSError errorWithDomain:@"Sample error" code:124 userInfo:nil]];
  }
                       onQueue:self.alternativeQueue]
   onErrorOnSameQueue:^(NSError *value){
     assertIfNotOnAlternativeQueue();
     [[TestSemaphore sharedInstance] lift:@"testOnErrorsAreCalledInRightQueuesSPECIFIED"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testOnErrorsAreCalledInRightQueuesSPECIFIED"];
}

- (void)testReactionThenObserveWithoutMethodAsync {
  NSNumber *number = @12;
  [[number then:^{
  } REACTION_BLOCK]
  observe:^(NSNumber *value) {
    XCTAssertEqual(value, number, @"Observe for immediate value should get oryginal value.");
    [[TestSemaphore sharedInstance] lift:@"testReactionThenObserveWithoutMethodAsync"];
  } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testReactionThenObserveWithoutMethodAsync"];
}

- (void)testReactionRunFromSubstituteThread {
  NSNumber *number = @12;
  [[[NSNumber reactionWithBlock:^id{
    return number;
  } REACTION_BLOCK]
    then:^{
  } REACTION_BLOCK]
   observe:^(NSNumber *value) {
     XCTAssertEqual(value, number, @"Observe for generated value should get generated value.");
     [[TestSemaphore sharedInstance] lift:@"testReactionRunFromSubstituteThread"];
   } REACTION_BLOCK];
  
  [[TestSemaphore sharedInstance] waitForKey:@"testReactionRunFromSubstituteThread"];
}

- (void)testObjectLifecycleIsEqualToDurarationOfObservation {
  __weak NSObject *object = nil;
  @autoreleasepool {
    object = [[[[[NSObject reactionWithBlock:^id{ return @12; } REACTION_BLOCK]
                 then:^{  } REACTION_BLOCK]
                then:^{  } REACTION_BLOCK]
               process:^id(id value) { return value; } REACTION_BLOCK]
              observe:^(id value) {
                [NSThread sleepForTimeInterval:0.01f];
                [[TestSemaphore sharedInstance] lift:@"testObjectLifecycleIsLongerOrEqualToDurarationOfObservation"];
              } REACTION_BLOCK];
    XCTAssertNotNil(object, @"Object should still exist");
    
    [[TestSemaphore sharedInstance] waitForKey:@"testObjectLifecycleIsLongerOrEqualToDurarationOfObservation"];
    //wait some more
    [NSThread sleepForTimeInterval:0.2f];
  }
  XCTAssertNil(object, @"Object should be already dead");
}

- (void)testConcurrentReactions {
  NSMutableArray *semaphores = [NSMutableArray array];
  dispatch_suspend(self.alternativeQueue);
  dispatch_suspend(self.mainQueueSubstitute);
  
  for (int i = 0; i < 100; i++) {
    [[[NSString reactionWithBlock:^id{
      //A sample block
      return @"TEST";
    } REACTION_BLOCK] then:^{
      
    } REACTION_BLOCK] observe:^(id value) {
      NSString *semaphoreId = [NSString stringWithFormat:@"testConcurrentReactions_%d", i * 10 + 4];
      [semaphores addObject:semaphoreId];
      [[TestSemaphore sharedInstance] lift:semaphoreId];
    } REACTION_BLOCK onQueue:self.alternativeQueue];
    
    [[[NSString reactionWithBlock:^id{
      //A sample block
      return @"TEST";
    } REACTION_BLOCK onQueue:self.mainQueueSubstitute] then:^{
      
    } REACTION_BLOCK onQueue:self.alternativeQueue] observe:^(id value) {
      NSString *semaphoreId = [NSString stringWithFormat:@"testConcurrentReactions_%d", i * 10];
      [semaphores addObject:semaphoreId];
      [[TestSemaphore sharedInstance] lift:semaphoreId];
    } REACTION_BLOCK];
    
    [[[NSString reactionWithBlock:^id{
      //A sample block
      return @"TEST";
    } REACTION_BLOCK] then:^{
      
    } REACTION_BLOCK onQueue:self.alternativeQueue] observe:^(id value) {
      NSString *semaphoreId = [NSString stringWithFormat:@"testConcurrentReactions_%d", i * 10 + 1];
      [semaphores addObject:semaphoreId];
      [[TestSemaphore sharedInstance] lift:semaphoreId];
    } REACTION_BLOCK];
    
    
    [[[NSString reactionWithBlock:^id{
      //A sample block
      return @"TEST";
    } REACTION_BLOCK onQueue:self.alternativeQueue] then:^{
      
    } REACTION_BLOCK onQueue:self.alternativeQueue] observe:^(id value) {
      NSString *semaphoreId = [NSString stringWithFormat:@"testConcurrentReactions_%d", i * 10 + 2];
      [semaphores addObject:semaphoreId];
      [[TestSemaphore sharedInstance] lift:semaphoreId];
    } REACTION_BLOCK];
    
    [[[NSString reactionWithBlock:^id{
      //A sample block
      return @"TEST";
    } REACTION_BLOCK] then:^{
      
    } REACTION_BLOCK onQueue:self.alternativeQueue] observe:^(id value) {
      NSString *semaphoreId = [NSString stringWithFormat:@"testConcurrentReactions_%d", i * 10 + 3];
      [semaphores addObject:semaphoreId];
      [[TestSemaphore sharedInstance] lift:semaphoreId];
    } REACTION_BLOCK];

  }
  
  dispatch_resume(self.alternativeQueue);
  dispatch_resume(self.mainQueueSubstitute);
  
  for (NSString *semaphoreId in semaphores) {
    [[TestSemaphore sharedInstance] waitForKey:semaphoreId];
  }
}

@end
