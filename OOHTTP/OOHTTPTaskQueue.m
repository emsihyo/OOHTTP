//
//  OOHTTPTaskQueue.m
//  OOHTTP
//
//  Created by emsihyo on 2018/3/29.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import "OOHTTPTaskQueue.h"
#import "AFHTTPRequestSerializer+OOHTTP.h"

NSErrorDomain const OOHTTPTaskErrorDomain = @"OOHTTPTaskErrorDomainKey";

@interface OOHTTPTaskQueue ()

@property (nonatomic,strong) AFHTTPSessionManager       *manager;
@property (nonatomic,assign) Class                      taskClass;
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic,strong) dispatch_source_t          timer;

@end

@interface OOHTTPTask ()

@property (nonatomic,assign) BOOL             ooExecuting;
@property (nonatomic,assign) BOOL             ooFinished;
@property (nonatomic,strong) NSString         *urlString;
@property (nonatomic,strong) NSString         *urlStringWithHeaderKey;
@property (nonatomic,strong) NSDictionary     *headers;
@property (nonatomic,strong) NSDictionary     *parameters;
@property (nonatomic,strong) id               responseObject;
@property (nonatomic,strong) NSURLSessionTask *task;
@property (nonatomic,weak  ) OOHTTPTaskQueue  *taskQueue;
@property (nonatomic,strong) NSError          *error;
@property (nonatomic,strong) NSLock           *lock;
@property (nonatomic,assign) NSInteger        currentRetryTime;
@property (nonatomic,strong) OOHTTPRetryInterval (^retryAfter)(OOHTTPTask * task,NSInteger currentRetryTime,NSError * error);
@property (nonatomic,strong) void (^constructingBodyBlock) (id <AFMultipartFormData> formData);
@property (nonatomic,strong) void (^finishBlock)(OOHTTPTask *task,id reponseObject,NSError* error);
@property (nonatomic,strong) void (^progressBlock) (NSProgress * progress);
@property (nonatomic,strong) dispatch_source_t after;

@end

@implementation OOHTTPTask

+ (instancetype)POST:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block progress:(void (^)(NSProgress *uploadProgress))uploadProgress taskQueue:(__kindof NSOperationQueue*)taskQueue completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[[self alloc]init];
    task.urlString=[url isKindOfClass:NSURL.class]?[url absoluteString]:url;
    task.headers=headers;
    task.parameters=parameters;
    task.finishBlock = completion;
    task.constructingBodyBlock = block;
    task.progressBlock = uploadProgress;
    task.retryAfter = retryAfter;
    task.taskQueue=taskQueue;
    [taskQueue addOperation:task];
    return task;
    
}

- (instancetype)init{
    self=[super init];
    if (!self)return nil;
    self.lock=[[NSLock alloc]init];
    return self;
}
- (void)setOoFinished:(BOOL)mFinished{
    [self willChangeValueForKey:@"isFinished"];
    _ooFinished=mFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setOoExecuting:(BOOL)mExecuting{
    [self willChangeValueForKey:@"isExecuting"];
    _ooExecuting=mExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting{
    return _ooExecuting;
}

- (BOOL)isFinished{
    return _ooFinished;
}

- (BOOL)isConcurrent{
    return YES;
}

- (BOOL)isAsynchronous{
    return YES;
}

- (void)start{
    [self.lock lock];
    [self _start];
    [self.lock unlock];
}

- (void)_start{
    if (self.isCancelled) {
        self.ooFinished=YES;
        self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"取消操作", nil)}];
        [self notify:nil error:self.error];
        return;
    }
    self.ooExecuting=YES;
    AFHTTPSessionManager *manager=self.taskQueue.manager;
    if (!manager) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"取消操作", nil)}];
        [self notify:nil error:self.error];
        return;
    }
    if (self.headers) {
        if (!self.urlStringWithHeaderKey) {
            NSURLComponents *urlComponents=[NSURLComponents componentsWithString:self.urlString];
            if (!urlComponents) {
                self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorClientError userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"客户端错误", nil)}];
                [self notify:nil error:self.error];
                return;
            }
            NSString *headerKey=[[NSUUID UUID]UUIDString];
            NSMutableArray *items=[[urlComponents queryItems] mutableCopy];
            if (!items) {
                items=[NSMutableArray array];
            }
            NSURLQueryItem *item=[NSURLQueryItem queryItemWithName:oo_http_header_key value:headerKey];
            [items addObject:item];
            urlComponents.queryItems=items;
            self.urlStringWithHeaderKey=[urlComponents string];
            [manager.requestSerializer oo_http_setHTTPHeaders:self.headers forKey:oo_http_header_key];
        }
    }else{
        self.urlStringWithHeaderKey=self.urlString;
    }
    __weak typeof(self) weakSelf=self;
    if (self.constructingBodyBlock) {
        self.task=[manager POST:self.urlStringWithHeaderKey parameters:self.parameters constructingBodyWithBlock:self.constructingBodyBlock progress:self.progressBlock success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [weakSelf taskDidFinish:task response:responseObject error:nil];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [weakSelf taskDidFinish:task response:nil error:error];
        }];
    }else{
        self.task=[manager POST:self.urlStringWithHeaderKey parameters:self.parameters progress:self.progressBlock success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [weakSelf taskDidFinish:task response:responseObject error:nil];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [weakSelf taskDidFinish:task response:nil error:error];
        }];
    }
}

- (void)taskDidFinish:(NSURLSessionTask *)task response:(id)responseObject error:(NSError *)error{
    [self.lock lock];
    self.task=nil;
    self.responseObject=responseObject;
    if (self.isCancelled||self.isFinished) {
        [self.lock unlock];
        return;
    }
    if (!error) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        [self notify:responseObject error:nil];
        [self.lock unlock];
        return;
    }
    if ([error.domain isEqualToString:AFURLRequestSerializationErrorDomain]) {
        self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorClientError userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"客户端错误", nil),NSUnderlyingErrorKey:error}];
    }else if([error.domain isEqualToString:AFURLResponseSerializationErrorDomain]){
        self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorClientError userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"服务端错误", nil),NSUnderlyingErrorKey:error}];
    }else if([error.domain isEqualToString:NSURLErrorDomain]){
        switch (error.code) {
            case NSURLErrorCancelled:
                self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"取消操作", nil),NSUnderlyingErrorKey:error}];
                break;
            case NSURLErrorTimedOut:
                self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorBadNetwork userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"请求超时", nil),NSUnderlyingErrorKey:error}];
                break;
            case NSURLErrorNotConnectedToInternet:
                self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorNonNetwork userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"无网络", nil),NSUnderlyingErrorKey:error}];
                break;
            default:
                self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorBadNetwork userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"网络或者服务器异常", nil),NSUnderlyingErrorKey:error}];
                break;
        }
    }
    if (!self.retryAfter) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        [self notify:nil error:self.error];
        [self.lock unlock];
        return;
    }
    OOHTTPRetryInterval interval=self.retryAfter(self,++self.currentRetryTime,error);
    if (interval==HTTRetryDisabled) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        [self notify:responseObject error:self.error];
        [self.lock unlock];
        return;
    }
    AFHTTPSessionManager *manager=self.taskQueue.manager;
    if (!manager) {
        self.ooExecuting=NO;
        self.ooFinished=YES;
        self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"取消操作", nil)}];
        [self notify:responseObject error:self.error];
        [self.lock unlock];
        return;
    }
    __weak typeof(self) weakSelf=self;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, manager.completionQueue?manager.completionQueue:dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        dispatch_source_cancel(weakSelf.after);
        weakSelf.after=nil;
        [weakSelf _start];
    });
    dispatch_resume(timer);
    self.after=timer;
    [self.lock unlock];
}


- (void)notify:(id)responseObject error:(NSError*)error{
    [self.taskQueue.manager.requestSerializer oo_http_removeHTTPHeadersForKey:self.urlStringWithHeaderKey];
    if(self.finishBlock) self.finishBlock(self,responseObject,error);
}

- (void)cancel{
    [self.lock lock];
    self.ooExecuting=NO;
    self.ooFinished=YES;
    if (self.after) {
        dispatch_source_cancel(self.after);
        self.after=nil;
    }
    if (self.task) [self.task cancel];
    self.error=[NSError errorWithDomain:OOHTTPTaskErrorDomain code:OOHTTPTaskErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"取消操作", nil)}];
    [self notify:nil error:self.error];
    [self.lock unlock];
}

@end

@implementation OOHTTPTaskQueue

- (void)dealloc{
    [self cancelAllOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer=nil;
    }
}

- (instancetype)init{
    self=[self initWithHTTPSessionManager:[AFHTTPSessionManager manager] taskClass:nil];
    if (!self) return nil;
    return self;
}

- (instancetype)initWithHTTPSessionManager:(AFHTTPSessionManager*)sessionManager taskClass:(Class)taskClass{
    self=[super init];
    if (!self) return nil;
    self.manager=sessionManager;
    NSParameterAssert(taskClass==nil||[taskClass isKindOfClass:OOHTTPTask.class]);
    self.taskClass=taskClass?taskClass:OOHTTPTask.class;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    return self;
}

- (void)appDidEnterBackground{
    self.backgroundTaskId=[[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
        [self cancelAllOperations];
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId=UIBackgroundTaskInvalid;
    }];
    if (self.timer) {
        dispatch_source_cancel(self.timer);
    }
    __weak typeof(self)weakSelf=self;
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
        if ([UIApplication sharedApplication].backgroundTimeRemaining<10) {
            if (weakSelf.timer) {
                dispatch_source_cancel(weakSelf.timer);
            }
            [[UIApplication sharedApplication] endBackgroundTask:weakSelf.backgroundTaskId];
            weakSelf.backgroundTaskId=UIBackgroundTaskInvalid;
        }
    });
    dispatch_resume(self.timer);
}

- (void)appWillEnterForeground{
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer=nil;
    }
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
    self.backgroundTaskId=UIBackgroundTaskInvalid;
}

- (OOHTTPTask *)POST:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block progress:(void (^)(NSProgress *uploadProgress))uploadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion{
    OOHTTPTask *task=[self.taskClass POST:url headers:headers parameters:parameters retryAfter:retryAfter constructingBodyWithBlock:block progress:uploadProgress taskQueue:self completion:completion];
    return task;

}
@end
