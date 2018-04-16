//
//  OOHTTPTask.m
//  OOHTTP
//
//  Created by emsihyo on 2018/3/29.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AFHTTPRequestSerializer+OOHTTP.h"
#import "OOHTTPTask.h"

#if OOHTTPLogEnabled
#define OOHTTPLog(format,...) printf("\n%s\n",[[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String])
#else
#define OOHTTPLog(x,...)
#endif

@interface OOHTTPTask ()

@property (nonatomic,assign) BOOL                       ooExecuting;
@property (nonatomic,assign) BOOL                       ooFinished;
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic,strong) NSRecursiveLock            *lock;
@property (nonatomic,strong) NSURLSessionTask           *sessionTask;
@property (nonatomic,strong) AFHTTPSessionManager       *sessionManager;

@property (nonatomic,assign) NSInteger      currentRetryTime;
@property (nonatomic,assign) OOHTTPTaskType taskType;
@property (nonatomic,strong) NSDictionary   *headers;
@property (nonatomic,strong) NSDictionary   *parameters;
@property (nonatomic,strong) NSError        *latestError;
@property (nonatomic,strong) NSDate         *startDate;
@property (nonatomic,strong) NSDate         *endDate;
@property (nonatomic,strong) NSDate         *latestStartDate;
@property (nonatomic,strong) NSDate         *latestEndDate;
@property (nonatomic,strong) NSString       *urlString;
@property (nonatomic,strong) NSString       *urlStringWithHeaderKey;
@property (nonatomic,strong) id             responseObject;

@property (nonatomic,strong) OOHTTPRetryInterval (^retryAfter)(OOHTTPTask * task,NSInteger currentRetryTime,NSError * latestError);
@property (nonatomic,strong) void (^constructingBody) (id <AFMultipartFormData> formData);
@property (nonatomic,strong) void (^completion)(OOHTTPTask *task,id reponseObject,NSError* error);
@property (nonatomic,strong) void (^uploadProgress) (NSProgress * progress);
@property (nonatomic,strong) void (^downloadProgress) (NSProgress * progress);
@property (nonatomic,strong) dispatch_source_t after;

@end

@implementation OOHTTPTask

- (void)dealloc{
    OOHTTPLog(@"OOHTTPTask dealloc");
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

+ (instancetype)task:(AFHTTPSessionManager*)sessionManager taskType:(OOHTTPTaskType)taskType Url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter constructingBody:(void (^)(id <AFMultipartFormData> formData))constructingBody uploadProgress:(void (^)(NSProgress *progress))uploadProgress downloadProgress:(void (^)(NSProgress *progress))downloadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[[self alloc]init];
    task.sessionManager=sessionManager;
    task.taskType=taskType;
    task.urlString=[url isKindOfClass:NSURL.class]?[url absoluteString]:url;
    task.headers=headers;
    task.parameters=parameters;
    task.retryAfter = retryAfter;
    task.constructingBody = constructingBody;
    task.uploadProgress = uploadProgress;
    task.downloadProgress = downloadProgress;
    task.completion = completion;
    return task;
}

+ (instancetype)GET:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter downloadProgress:(void (^)(NSProgress *progress))downloadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    return [self task:sessionManager taskType:OOHTTPTaskTypeGet Url:url headers:headers parameters:parameters retryAfter:retryAfter constructingBody:nil uploadProgress:nil downloadProgress:downloadProgress completion:completion];
}

+ (instancetype)POST:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter constructingBody:(void (^)(id <AFMultipartFormData> formData))constructingBody uploadProgress:(void (^)(NSProgress *progress))uploadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    return [self task:sessionManager taskType:OOHTTPTaskTypePost Url:url headers:headers parameters:parameters retryAfter:retryAfter constructingBody:constructingBody uploadProgress:uploadProgress downloadProgress:nil completion:completion];
}

+ (instancetype)HEAD:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    return [self task:sessionManager taskType:OOHTTPTaskTypeHead Url:url headers:headers parameters:parameters retryAfter:retryAfter constructingBody:nil uploadProgress:nil downloadProgress:nil completion:completion];
}

+ (instancetype)PUT:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    return [self task:sessionManager taskType:OOHTTPTaskTypePut Url:url headers:headers parameters:parameters retryAfter:retryAfter constructingBody:nil uploadProgress:nil downloadProgress:nil completion:completion];
}

+ (instancetype)PATCH:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    return [self task:sessionManager taskType:OOHTTPTaskTypePatch Url:url headers:headers parameters:parameters retryAfter:retryAfter constructingBody:nil uploadProgress:nil downloadProgress:nil completion:completion];
}

+ (instancetype)DELETE:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    return [self task:sessionManager taskType:OOHTTPTaskTypeDelete Url:url headers:headers parameters:parameters retryAfter:retryAfter constructingBody:nil uploadProgress:nil downloadProgress:nil completion:completion];
}

- (instancetype)init{
    self=[super init];
    if (!self)return nil;
    self.lock=[[NSRecursiveLock alloc]init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    return self;
}

- (void)start{
    [self.lock lock];
    self.startDate=[NSDate date];
    [self _start];
    dispatch_sync(dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].applicationState!=UIApplicationStateBackground) return;
        [self beginBackgroundTaskIfNeed];
    });
    [self.lock unlock];
}

- (void)cancel{
    [self.lock lock];
    [super cancel];
    [self _cancel];
    self.latestError=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"The connection was cancelled.", nil)}];
    [self notify:nil error:self.latestError];
    [self.lock unlock];
    OOHTTPLog(@"task did cancel");
}

- (void)_cancel{
    if (self.after) {
        dispatch_source_cancel(self.after);
        self.after=nil;
    }
    if (self.sessionTask) {
        [self.sessionTask cancel];
        self.sessionTask=nil;
    }
}

- (void)_start{
    [self _cancel];
    if (self.isCancelled) return;
    if (!self.isReady) return;
    self.latestStartDate=[NSDate date];
    self.latestEndDate=nil;
    if (self.currentRetryTime) OOHTTPLog(@"task retrying for time:%d",self.currentRetryTime);
    else OOHTTPLog(@"task did start");
    self.ooExecuting=YES;
    AFHTTPSessionManager *sessionManager=self.sessionManager;
    NSCParameterAssert(sessionManager);
    if (!self.headers.count) self.urlStringWithHeaderKey=self.urlString;
    else if (!self.urlStringWithHeaderKey) {
        NSURLComponents *urlComponents=[NSURLComponents componentsWithString:self.urlString];
        if (!urlComponents) {
            self.ooExecuting=NO;
            self.ooFinished=YES;
            self.latestError=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
            [self notify:nil error:self.latestError];
            return;
        }
        NSString *headerKey=[[NSUUID UUID]UUIDString];
        NSMutableArray *items=[[urlComponents queryItems] mutableCopy];
        if (!items) items=[NSMutableArray array];
        [items addObject:[NSURLQueryItem queryItemWithName:oo_http_header_key value:headerKey]];
        urlComponents.queryItems=items;
        self.urlStringWithHeaderKey=[urlComponents string];
        [sessionManager.requestSerializer oo_http_setHTTPHeaders:self.headers forKey:headerKey];
    }
    __weak typeof(self) weakSelf=self;
    switch (self.taskType) {
        case OOHTTPTaskTypeGet:{
            self.sessionTask=[sessionManager GET:self.urlStringWithHeaderKey parameters:self.parameters progress:self.downloadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf taskDidFinish:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
        case OOHTTPTaskTypePost:{
            if (self.constructingBody) {
                self.sessionTask=[sessionManager POST:self.urlStringWithHeaderKey parameters:self.parameters constructingBodyWithBlock:self.constructingBody progress:self.uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [weakSelf taskDidFinish:task response:responseObject error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [weakSelf taskDidFinish:task response:nil error:error];
                }];
            }else{
                self.sessionTask=[sessionManager POST:self.urlStringWithHeaderKey parameters:self.parameters progress:self.uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [weakSelf taskDidFinish:task response:responseObject error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [weakSelf taskDidFinish:task response:nil error:error];
                }];
            }
        } break;
        case OOHTTPTaskTypeHead:{
            self.sessionTask=[sessionManager HEAD:self.urlStringWithHeaderKey parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task) {
                [weakSelf taskDidFinish:task response:nil error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
        case OOHTTPTaskTypePut:{
            self.sessionTask=[sessionManager PUT:self.urlStringWithHeaderKey parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf taskDidFinish:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
        case OOHTTPTaskTypePatch:{
            self.sessionTask=[sessionManager PATCH:self.urlStringWithHeaderKey parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf taskDidFinish:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
        case OOHTTPTaskTypeDelete:{
            self.sessionTask=[sessionManager DELETE:self.urlStringWithHeaderKey parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf taskDidFinish:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
    }
}

- (void)taskDidFinish:(NSURLSessionTask *)task response:(id)responseObject error:(NSError *)error{
    [self.lock lock];
    self.sessionTask=nil;
    if (self.isFinished||self.isCancelled) {
        [self.lock unlock];
        return;
    }
    if (!error) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        self.responseObject=responseObject;
        [self notify:self.responseObject error:nil];
        [self.lock unlock];
        return;
    }
    if ([error.domain isEqualToString:NSURLErrorDomain]&&error.code==NSURLErrorCancelled) {
        [self.lock unlock];
        return;
    }
    self.latestError=error;
    if (!self.retryAfter) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        [self notify:nil error:self.latestError];
        [self.lock unlock];
        return;
    }
    OOHTTPRetryInterval interval=self.retryAfter(self,++self.currentRetryTime,error);
    if (interval==OOHTTPRetryDisabled) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        [self notify:nil error:self.latestError];
        [self.lock unlock];
        return;
    }
    self.latestEndDate=[NSDate date];
    if (self.backgroundTaskId) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            OOHTTPLog(@"task did fail, will retry after interval:%.2f,timeRemaining:%3.2f",interval,[UIApplication sharedApplication].backgroundTimeRemaining);
        });
    }else{
        OOHTTPLog(@"task did fail, will retry after interval:%.2f, latest duration:%.2f, total duration:%.2f",interval,self.latestDuration,self.totalDuration);
    }
    __weak typeof(self) weakSelf=self;
    self.after = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, [NSOperationQueue currentQueue].underlyingQueue?[NSOperationQueue currentQueue].underlyingQueue:dispatch_get_main_queue());
    dispatch_source_set_timer(self.after, dispatch_walltime(DISPATCH_TIME_NOW, interval*NSEC_PER_SEC), DBL_MAX * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.after, ^{
        __strong typeof(weakSelf) self=weakSelf;
        dispatch_source_cancel(self.after);
        self.after=nil;
        [self _start];
    });
    dispatch_resume(self.after);
    [self.lock unlock];
}

- (void)notify:(id)responseObject error:(NSError*)error{
    self.latestEndDate=[NSDate date];
    self.endDate=self.latestEndDate;
    [self.sessionManager.requestSerializer oo_http_removeHTTPHeadersForKey:self.urlStringWithHeaderKey];
    if(self.completion) self.completion(self,responseObject,error);
    OOHTTPLog(@"task did finish:%@",error);
}

- (void)appDidEnterBackground{
    [self.lock lock];
    [self beginBackgroundTaskIfNeed];
    [self.lock unlock];
}

- (void)appWillEnterForeground{
    [self.lock lock];
    [self endBackgroundTaskIfNeed];
    if (self.sessionTask||self.after) {
        [self.lock unlock];
        return;
    }
    [self _start];
    [self.lock unlock];
}

- (void)beginBackgroundTaskIfNeed{
    if (self.backgroundTaskId!=UIBackgroundTaskInvalid) return;
    if (!self.isExecuting) return;
    __weak typeof(self) weakSelf=self;
    self.backgroundTaskId=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        __strong typeof(weakSelf) self=weakSelf;
        [self.lock lock];
        if (self.isExecuting) {
            [self _cancel];
        }
        [self.lock unlock];
        self.backgroundTaskId=UIBackgroundTaskInvalid;
        OOHTTPLog(@"background task did expire");
    }];
    OOHTTPLog(@"did begin background task");
}

- (void)endBackgroundTaskIfNeed{
    if (self.backgroundTaskId==UIBackgroundTaskInvalid) return;
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
    self.backgroundTaskId=UIBackgroundTaskInvalid;
    OOHTTPLog(@"did end background task");
}

- (void)setOoFinished:(BOOL)ooFinished{
    [self willChangeValueForKey:@"isFinished"];
    _ooFinished=ooFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setOoExecuting:(BOOL)ooExecuting{
    [self willChangeValueForKey:@"isExecuting"];
    _ooExecuting=ooExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting{
    return _ooExecuting;
}

- (BOOL)isFinished{
    return _ooFinished;
}

- (BOOL)isAsynchronous{
    return YES;
}

- (NSTimeInterval)totalDuration{
    [self.lock lock];
    if (!self.startDate) {
        [self.lock unlock];
        return 0;
    }
    NSDate *date=self.endDate;
    if (!date) date=[NSDate date];
    NSTimeInterval duration = [date timeIntervalSinceDate:self.startDate];
    [self.lock unlock];
    return duration;
}

- (NSTimeInterval)latestDuration{
    [self.lock lock];
    if (!self.latestStartDate) {
        [self.lock unlock];
        return 0;
    }
    NSDate *date=self.latestEndDate;
    if (!date) date=[NSDate date];
    NSTimeInterval duration = [date timeIntervalSinceDate:self.latestStartDate];
    [self.lock unlock];
    return duration;
}

@end


