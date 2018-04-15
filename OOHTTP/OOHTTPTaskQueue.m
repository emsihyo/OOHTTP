//
//  OOHTTPTaskQueue.m
//  OOHTTP
//
//  Created by emsihyo on 2018/3/29.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AFHTTPRequestSerializer+OOHTTP.h"
#import "OOHTTPTaskQueue.h"

static void * OOHTTPContext = &OOHTTPContext;

typedef NS_ENUM(NSInteger,OOHTTPTaskType) {
    OOHTTPTaskTypeGet,
    OOHTTPTaskTypePost,
    OOHTTPTaskTypeHead,
    OOHTTPTaskTypePut,
    OOHTTPTaskTypePatch,
    OOHTTPTaskTypeDelete
};

@interface OOHTTPTask ()

@property (nonatomic,assign) BOOL                 ooExecuting;
@property (nonatomic,assign) BOOL                 ooFinished;
@property (nonatomic,strong) NSLock               *lock;
@property (nonatomic,weak)   OOHTTPTaskQueue      *taskQueue;
@property (nonatomic,assign) OOHTTPTaskType       taskType;
@property (nonatomic,strong) NSString             *urlString;
@property (nonatomic,strong) NSString             *urlStringWithHeaderKey;
@property (nonatomic,strong) NSDictionary         *headers;
@property (nonatomic,strong) NSDictionary         *parameters;
@property (nonatomic,strong) id                   responseObject;

@property (readonly        ) AFHTTPSessionManager *sessionManager;
@property (nonatomic,strong) NSURLSessionTask     *sessionTask;

@property (nonatomic,assign) NSInteger            currentRetryTime;
@property (nonatomic,strong) NSError              *latestError;

@property (nonatomic,strong) OOHTTPRetryInterval (^retryAfter)(OOHTTPTask * task,NSInteger currentRetryTime,NSError * error);
@property (nonatomic,strong) void (^constructingBody) (id <AFMultipartFormData> formData);
@property (nonatomic,strong) void (^completion)(OOHTTPTask *task,id reponseObject,NSError* error);
@property (nonatomic,strong) void (^uploadProgress) (NSProgress * progress);
@property (nonatomic,strong) void (^downloadProgress) (NSProgress * progress);
@property (nonatomic,strong) dispatch_source_t after;

@end

@interface OOHTTPTaskQueue ()

@property (nonatomic,assign) Class                      taskClass;
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic,strong) AFHTTPSessionManager       *sessionManager;

@end

@implementation OOHTTPTaskQueue

- (void)dealloc{
    [self cancelAllOperations];
    [self removeObserver:self forKeyPath:@"operationCount" context:OOHTTPContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init{
    self=[self initWithHTTPSessionManager:[AFHTTPSessionManager manager] taskClass:nil];
    if (!self) return nil;
    return self;
}

- (instancetype)initWithHTTPSessionManager:(AFHTTPSessionManager*)sessionManager taskClass:(Class)taskClass{
    self=[super init];
    if (!self) return nil;
    NSParameterAssert(taskClass==nil||[taskClass isKindOfClass:OOHTTPTask.class]);
    self.sessionManager=sessionManager;
    self.taskClass=taskClass?taskClass:OOHTTPTask.class;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:OOHTTPContext];
    return self;
}

- (void)appDidEnterBackground{
    [self beginBackgroundTaskIfNeed];
}

- (void)appWillEnterForeground{
    [self endBackgroundTaskIfNeed];
}

- (void)beginBackgroundTaskIfNeed{
    if ([UIApplication sharedApplication].applicationState!=UIApplicationStateBackground) return;
    if (self.backgroundTaskId!=UIBackgroundTaskInvalid) return;
    if (self.operationCount==0) return;
    __weak typeof(self)weakSelf=self;
    self.backgroundTaskId=[[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
        __strong typeof(weakSelf) self = weakSelf;
        super.suspended=YES;
        self.backgroundTaskId=UIBackgroundTaskInvalid;
    }];
}

- (void)endBackgroundTaskIfNeed{
    if (super.suspended) super.suspended=NO;
    if (self.backgroundTaskId==UIBackgroundTaskInvalid) return;
    [[UIApplication sharedApplication]endBackgroundTask:self.backgroundTaskId];
    self.backgroundTaskId=UIBackgroundTaskInvalid;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (context!=OOHTTPContext) return;
    if (![keyPath isEqualToString:@"operationCount"]) return;
    if ([change[NSKeyValueChangeNewKey] integerValue]==0) [self endBackgroundTaskIfNeed];
    else [self beginBackgroundTaskIfNeed];
}

- (OOHTTPTask*)createTaskWithURL:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task = [[OOHTTPTask alloc]init];
    task.urlString = [url isKindOfClass:NSURL.class]?[url absoluteURL]:url;
    task.headers = headers;
    task.parameters = parameters;
    task.retryAfter = retryAfter;
    task.completion = completion;
    task.taskQueue = self;
    return task;
}

- (OOHTTPTask *)GET:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter   downloadProgress:(void (^)(NSProgress *progress))downloadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[self createTaskWithURL:url headers:headers parameters:parameters retryAfter:retryAfter completion:completion];
    task.taskType=OOHTTPTaskTypeGet;
    task.downloadProgress = downloadProgress;
    [super addOperation:task];
    return task;
}

- (OOHTTPTask *)POST:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter constructingBody:(void (^)(id <AFMultipartFormData> formData))constructingBody uploadProgress:(void (^)(NSProgress *progress))uploadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[self createTaskWithURL:url headers:headers parameters:parameters retryAfter:retryAfter completion:completion];
    task.taskType=OOHTTPTaskTypePost;
    task.uploadProgress = uploadProgress;
    task.constructingBody = constructingBody;
    [super addOperation:task];
    return task;
}

- (OOHTTPTask *)HEAD:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter  completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[self createTaskWithURL:url headers:headers parameters:parameters retryAfter:retryAfter completion:completion];
    task.taskType=OOHTTPTaskTypeHead;
    [super addOperation:task];
    return task;
}

- (OOHTTPTask *)PUT:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[self createTaskWithURL:url headers:headers parameters:parameters retryAfter:retryAfter completion:completion];
    task.taskType=OOHTTPTaskTypePut;
    [super addOperation:task];
    return task;
}

- (OOHTTPTask *)PATCH:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[self createTaskWithURL:url headers:headers parameters:parameters retryAfter:retryAfter completion:completion];
    task.taskType=OOHTTPTaskTypePatch;
    [super addOperation:task];
    return task;
}

- (OOHTTPTask *)DELETE:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[self createTaskWithURL:url headers:headers parameters:parameters retryAfter:retryAfter completion:completion];
    task.taskType=OOHTTPTaskTypeDelete;
    [super addOperation:task];
    return task;
}

@end

@implementation OOHTTPTask

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"taskQueue.isSuspended" context:OOHTTPContext];
}

- (instancetype)init{
    self=[super init];
    if (!self)return nil;
    self.lock=[[NSLock alloc]init];
    [self addObserver:self forKeyPath:@"taskQueue.isSuspended" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionNew context:OOHTTPContext];
    return self;
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

- (AFHTTPSessionManager*)sessionManager{
    return [self.taskQueue sessionManager];
}

- (BOOL)isAsynchronous{
    return YES;
}

- (void)start{
    [self.lock lock];
    [self _start];
    [self.lock unlock];
}

- (void)cancel{
    [self.lock lock];
    [super cancel];
    [self _cancel];
    self.latestError=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"The connection was cancelled.", nil)}];
    [self notify:nil error:self.latestError];
    [self.lock unlock];
}

- (void)_cancel{
    if (self.after) {
        dispatch_source_cancel(self.after);
        self.after=nil;
    }
    if (self.sessionTask) [self.sessionTask cancel];
}

- (void)_start{
    [self _cancel];
    if (self.isCancelled) return;
    if (self.taskQueue.isSuspended) return;
    if (!self.isReady) return;
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
    if (self.isFinished||self.taskQueue.isSuspended||self.isCancelled) {
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
    self.latestError=error;
    if (!self.retryAfter) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        [self notify:nil error:self.latestError];
        [self.lock unlock];
        return;
    }
    OOHTTPRetryInterval interval=self.retryAfter(self,++self.currentRetryTime,error);
    if (interval==HTTRetryDisabled) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        [self notify:nil error:self.latestError];
        [self.lock unlock];
        return;
    }
    __weak typeof(self) weakSelf=self;
    self.after = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, [NSOperationQueue currentQueue].underlyingQueue?[NSOperationQueue currentQueue].underlyingQueue:dispatch_get_main_queue());
    dispatch_source_set_timer(self.after, DISPATCH_TIME_NOW, interval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
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
    [self.sessionManager.requestSerializer oo_http_removeHTTPHeadersForKey:self.urlStringWithHeaderKey];
    if(self.completion) self.completion(self,responseObject,error);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (context!=OOHTTPContext) return;
    if (![keyPath isEqualToString:@"taskQueue.isSuspended"]) return;
    [self.lock lock];
    if ([change[NSKeyValueChangeNewKey] boolValue]) [self _cancel];
    else [self _start];
    [self.lock unlock];
}
@end


