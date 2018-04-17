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

@interface OOHTTPTask ()

@property (nonatomic,assign) BOOL                       executing_;
@property (nonatomic,assign) BOOL                       finished_;
@property (nonatomic,assign) NSInteger                  currentRetryTime;
@property (nonatomic,assign) OOHTTPTaskType             taskType;
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic,strong) AFHTTPSessionManager       *sessionManager;
@property (nonatomic,strong) NSDictionary               *headers;
@property (nonatomic,strong) NSDictionary               *parameters;
@property (nonatomic,strong) NSError                    *latestError;
@property (nonatomic,strong) NSLock                     *lock;
@property (nonatomic,strong) NSString                   *urlString;
@property (nonatomic,strong) NSString                   *urlStringWithHeaderKey;
@property (nonatomic,strong) NSURLSessionTask           *sessionTask;
@property (nonatomic,strong) id                         responseObject;

@property (nonatomic,strong) OOHTTPRetryInterval (^retryAfter)(OOHTTPTask * task,NSInteger currentRetryTime,NSError * latestError);
@property (nonatomic,strong) void (^constructingBody) (id <AFMultipartFormData> formData);
@property (nonatomic,strong) void (^completion)(OOHTTPTask *task,id reponseObject,NSError* error);
@property (nonatomic,strong) void (^uploadProgress) (NSProgress * progress);
@property (nonatomic,strong) void (^downloadProgress) (NSProgress * progress);
@property (nonatomic,strong) dispatch_source_t after;

@end

@implementation OOHTTPTask

- (void)dealloc{
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
    self.lock=[[NSLock alloc]init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    return self;
}

- (void)start{
    [self.lock lock];
    [super start];
    [self beginBackgroundTask];
    [self _start];
    [self.lock unlock];
}

- (void)cancel{
    [self.lock lock];
    [self _cancel];
    self.latestError=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"The connection was cancelled.", nil)}];
    [self complete];
    [super cancel];
    [self.lock unlock];
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
    if (self.isCancelled||!self.isReady) return;
//    if (self.currentRetryTime) NSLog(@"\ntask retrying for time:%zd",self.currentRetryTime);
//    else NSLog(@"\ntask did start");
    self.executing_=YES;
    if (!self.headers.count) self.urlStringWithHeaderKey=self.urlString;
    else if (!self.urlStringWithHeaderKey) {
        NSURLComponents *urlComponents=[NSURLComponents componentsWithString:self.urlString];
        if (!urlComponents) {
            self.latestError=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"The connection failed due to a malformed URL.", nil)}];
            [self complete];
            return;
        }
        NSString *headerKey=[[NSUUID UUID]UUIDString];
        NSMutableArray *items=[[urlComponents queryItems] mutableCopy];
        if (!items) items=[NSMutableArray array];
        [items addObject:[NSURLQueryItem queryItemWithName:oo_http_header_key value:headerKey]];
        urlComponents.queryItems=items;
        self.urlStringWithHeaderKey=[urlComponents string];
        [self.sessionManager.requestSerializer oo_http_setHTTPHeaders:self.headers forKey:headerKey];
    }
    __weak typeof(self) weakSelf=self;
    switch (self.taskType) {
        case OOHTTPTaskTypeGet:{
            self.sessionTask=[self.sessionManager GET:self.urlStringWithHeaderKey parameters:self.parameters progress:self.downloadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf taskDidFinish:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
        case OOHTTPTaskTypePost:{
            if (self.constructingBody) {
                self.sessionTask=[self.sessionManager POST:self.urlStringWithHeaderKey parameters:self.parameters constructingBodyWithBlock:self.constructingBody progress:self.uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [weakSelf taskDidFinish:task response:responseObject error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [weakSelf taskDidFinish:task response:nil error:error];
                }];
            }else{
                self.sessionTask=[self.sessionManager POST:self.urlStringWithHeaderKey parameters:self.parameters progress:self.uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [weakSelf taskDidFinish:task response:responseObject error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [weakSelf taskDidFinish:task response:nil error:error];
                }];
            }
        } break;
        case OOHTTPTaskTypeHead:{
            self.sessionTask=[self.sessionManager HEAD:self.urlStringWithHeaderKey parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task) {
                [weakSelf taskDidFinish:task response:nil error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
        case OOHTTPTaskTypePut:{
            self.sessionTask=[self.sessionManager PUT:self.urlStringWithHeaderKey parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf taskDidFinish:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
        case OOHTTPTaskTypePatch:{
            self.sessionTask=[self.sessionManager PATCH:self.urlStringWithHeaderKey parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf taskDidFinish:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf taskDidFinish:task response:nil error:error];
            }];
        } break;
        case OOHTTPTaskTypeDelete:{
            self.sessionTask=[self.sessionManager DELETE:self.urlStringWithHeaderKey parameters:self.parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
    if (self.isCancelled) {
        [self.lock unlock];
        return;
    }
    if (!error) {
        self.responseObject=responseObject;
        self.latestError=nil;
        [self complete];
        [self.lock unlock];
        return;
    }
    if ([error.domain isEqualToString:NSURLErrorDomain]&&error.code==NSURLErrorCancelled) {
        [self.lock unlock];
        return;
    }
    self.latestError=error;
    if (!self.retryAfter) {
        [self complete];
        [self.lock unlock];
        return;
    }
    OOHTTPRetryInterval interval=self.retryAfter(self,++self.currentRetryTime,self.latestError);
    if (interval==OOHTTPRetryDisabled) {
        [self complete];
        [self.lock unlock];
        return;
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
//    NSLog(@"\ntask did fail, will retry after interval:%.2f",interval);
    [self.lock unlock];
}

- (void)complete{
    self.executing_=NO;
    self.finished_=YES;
    [self.sessionManager.requestSerializer oo_http_removeHTTPHeadersForKey:self.urlStringWithHeaderKey];
    if(self.completion) dispatch_async(self.sessionManager.completionQueue?self.sessionManager.completionQueue:dispatch_get_main_queue(), ^{
        self.completion(self,self.responseObject,self.latestError);
    });
    [self endBackgroundTask];
//    NSLog(@"\ntask did finish with error:%@",self.latestError);
}

- (void)applicationDidBecomeActive:(NSNotification*)nf{
    [self.lock lock];
    if (self.isExecuting&&self.backgroundTaskId==UIBackgroundTaskInvalid) {
        [self beginBackgroundTask];
        [self _start];
    }
    [self.lock unlock];
}

- (void)beginBackgroundTask{
    if (self.backgroundTaskId!=UIBackgroundTaskInvalid) return;
    __weak typeof(self) weakSelf=self;
    self.backgroundTaskId=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        __strong typeof(weakSelf) self=weakSelf;
        [self.lock lock];
        if (self.isExecuting) [self _cancel];
        self.backgroundTaskId=UIBackgroundTaskInvalid;
        [self.lock unlock];
//        NSLog(@"\nbackground task did expire");
    }];
//    NSLog(@"\ndid begin background task");
}

- (void)endBackgroundTask{
    if (self.backgroundTaskId==UIBackgroundTaskInvalid) return;
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
    self.backgroundTaskId=UIBackgroundTaskInvalid;
//    NSLog(@"\ndid end background task");
}

- (void)setFinished_:(BOOL)finished_{
    [self willChangeValueForKey:@"isFinished"];
    _finished_=finished_;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting_:(BOOL)executing_{
    [self willChangeValueForKey:@"isExecuting"];
    _executing_=executing_;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting{
    return _executing_;
}

- (BOOL)isFinished{
    return _finished_;
}

- (BOOL)isAsynchronous{
    return YES;
}


@end


