//
//  RetriableOperation.m
//  Retriable
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import "RetriableOperation.h"

//#define RetryLog(...) printf("\n%s\n",[[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#define RetryLog(...)

@interface RetriableOperation ()

@property (nonatomic,assign) BOOL                       _isExecuting;
@property (nonatomic,assign) BOOL                       _isFinished;

@property (nonatomic,strong) id                         request;
@property (nonatomic,strong) NSTimeInterval (^retryAfter)(id request,NSInteger currentRetryTime,NSError *latestError);
@property (nonatomic,strong) void(^_completion)(id response,NSError *latestError);
@property (nonatomic,strong) void(^_start)(id request,void(^response)(id response,NSError *error));
@property (nonatomic,strong) void(^_cancel)(id request);
@property (nonatomic,strong) NSArray<NSError*> *cancelledErrorTemplates;
@property (nonatomic,assign) BOOL                       isBackgroundTaskEnabled;

@property (nonatomic,strong) id                         response;
@property (nonatomic,strong) NSError                    *latestError;

@property (nonatomic,strong) NSLock                     *lock;
@property (nonatomic,strong) dispatch_source_t          timer;
@property (nonatomic,assign) NSInteger                  currentRetryTime;
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic,assign) BOOL                       isAppInBackground;
@end

@implementation RetriableOperation

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancel];
    RetryLog(@"operation: %@\nwill dealloc",self.request);
}

- (instancetype)initWithRequest:(id)request retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(id response,NSError *latestError))completion isBackgroundTaskEnabled:(BOOL)isBackgroundTaskEnabled start:(void(^)(id request,void(^completion)(id response,NSError *error)))start cancel:(void(^)(id request))cancel cancelledErrorTemplates:(NSArray<NSError*>*)cancelledErrorTemplates{
    self=[super init];
    if (!self) return self;
    self.lock=[[NSLock alloc]init];
    self.request=request;
    self.retryAfter = retryAfter;
    self._completion =completion;
    self._start = start;
    self._cancel = cancel;
    self.isBackgroundTaskEnabled=isBackgroundTaskEnabled;
    if (cancelledErrorTemplates.count>0) self.cancelledErrorTemplates=cancelledErrorTemplates;
    else self.cancelledErrorTemplates=@[[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    return self;
}

- (void)start{
    [self.lock lock];
    [self start__];
    [self.lock unlock];
}

- (void)cancel{
    [self.lock lock];
    if (self.isCancelled||self.isFinished) {
        [self.lock unlock];
        return;
    }
    [super cancel];
    [self cancel__];
    self.latestError=self.cancelledErrorTemplates.firstObject;
    [self complete];
    [self.lock unlock];
}

- (void)start__{
    if (self.isCancelled||self.isFinished||self.isPaused) return;
    if (!self.isBackgroundTaskEnabled){
        if (self.isAppInBackground) return;
    }else [self beginBackgroundTask];
    if (self.currentRetryTime==0) RetryLog(@"operation: %@\ndid start",self.request);
    else RetryLog(@"operation: %@\nretrying: %ld", self.request,(long)self.currentRetryTime);
    self._isExecuting=YES;
    __weak typeof(self) weakSelf=self;
    self._start(self.request, ^(id response, NSError *error) {
        __strong typeof(weakSelf) self=weakSelf;
        [self.lock lock];
        if (self.isCancelled||self.isFinished){
            [self.lock unlock];
            return;
        }
        for (NSError * template in self.cancelledErrorTemplates){
            if ([error.domain isEqualToString:template.domain]&&error.code==template.code){
                [self.lock unlock];
                return;
            }
        }
        self.response=response;self.latestError=error;
        if (!error||!self.retryAfter) {
            [self complete];
            [self.lock unlock];
            return;
        }
        NSTimeInterval interval=self.retryAfter(self.request,++self.currentRetryTime,self.latestError);
        if (interval==0) {
            [self complete];
            [self.lock unlock];
            return;
        }
        if ((self.isAppInBackground&&!self.isBackgroundTaskEnabled)||self.isPaused){
            [self.lock unlock];
            return;
        }
        if (self.timer) {
            NSAssert(0, @"there is a issue about duplicated response");
            dispatch_source_cancel(self.timer);
            self.timer=nil;
        }
        RetryLog(@"operation: %@\nwill retry after: %.2f, error: %@",self.request,interval,self.latestError);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(self.timer, dispatch_walltime(DISPATCH_TIME_NOW, interval*NSEC_PER_SEC), INT32_MAX * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.timer, ^{
            __strong typeof(weakSelf) self=weakSelf;
            [self.lock lock];
            dispatch_source_cancel(self.timer);
            self.timer=nil;
            [self start__];
            [self.lock unlock];
        });
        dispatch_resume(self.timer);
        [self.lock unlock];
    });
}

- (void)cancel__{
    self._cancel(self.request);
    if (!self.timer) return;
    dispatch_source_cancel(self.timer);
    self.timer=nil;
}

- (void)complete{
    self._isExecuting=NO;
    self._isFinished=YES;
    if (self._completion) self._completion(self.response, self.latestError);
    RetryLog(@"operation: %@\ndid complete\nresponse:%@\nerror:%@",self.request,self.response,self.latestError);
    [self endBackgroundTask];
}

#pragma mark --
#pragma mark -- background task

- (void)applicationWillEnterForeground{
    [self.lock lock];
    self.isAppInBackground=NO;
    if (!self.isExecuting||self.isPaused) {
        [self.lock unlock];
        return;
    }
    if (!self.isBackgroundTaskEnabled) [self start__];
    else if (self.backgroundTaskId==UIBackgroundTaskInvalid) [self start__];
    [self.lock unlock];
}

- (void)applicationDidEnterBackground{
    [self.lock lock];
    self.isAppInBackground=YES;
    if (self.isBackgroundTaskEnabled) {
        [self.lock unlock];
        return;
    }
    if (self.isExecuting&&!self.isPaused)[self cancel__];
    [self.lock unlock];
}

- (void)beginBackgroundTask{
    if (self.backgroundTaskId!=UIBackgroundTaskInvalid) return;
    __weak typeof(self) weakSelf=self;
    self.backgroundTaskId=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        __strong typeof(weakSelf) self=weakSelf;
        [self.lock lock];
        if (self.executing&&!self.isPaused) [self cancel__];
        self.backgroundTaskId=UIBackgroundTaskInvalid;
        RetryLog(@"operation: %@\nbackground task did expired",self.request);
        [self.lock unlock];
    }];
    RetryLog(@"operation: %@\nbackground task did begin",self.request);
}

- (void)endBackgroundTask{
    if (self.backgroundTaskId==UIBackgroundTaskInvalid) return;
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
    self.backgroundTaskId=UIBackgroundTaskInvalid;
    RetryLog(@"operation: %@\nbackground task did end",self.request);
}

- (void)setIsPaused:(BOOL)isPaused{
    [self.lock lock];
    if (_isPaused==isPaused) {
        [self.lock unlock];
        return;
    }
    _isPaused=isPaused;
    if (!self.executing||(self.isAppInBackground&&self.backgroundTaskId==UIBackgroundTaskInvalid)) {
        [self.lock unlock];
        return;
    }
    if (isPaused) [self cancel__];
    else [self start__];
    [self.lock unlock];
}

- (void)set_isExecuting:(BOOL)_isExecuting{
    [self willChangeValueForKey:@"isExecuting"];
    __isExecuting=_isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)set_isFinished:(BOOL)_isFinished{
    [self willChangeValueForKey:@"isFinished"];
    __isFinished=_isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isExecuting{
    return __isExecuting;
}

- (BOOL)isFinished{
    return __isFinished;
}

- (BOOL)isAsynchronous{
    return YES;
}

@end
