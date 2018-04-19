//
//  AFHTTPSessionManager+Retriable.m
//  RetriableAFNetworking
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <objc/runtime.h>

#import "AFHTTPSessionManager+Retriable.h"
#import "RetriableAFNetworkingRequest.h"
#import "RetriableAFNetworkingRequest+Private.h"
#import "RetriableAFNetworkingResponse.h"

@implementation AFHTTPSessionManager (Retriable)

- (NSOperationQueue*)retriable_operationQueue{
    NSOperationQueue *queue=objc_getAssociatedObject(self,@selector(retriable_operationQueue));
    if (queue) return queue;
    queue=[[NSOperationQueue alloc]init];
    objc_setAssociatedObject(self,@selector(retriable_operationQueue),queue,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return queue;
}

- (RetriableOperation*)retriable_GET:(NSString *)URLString parameters:(id)parameters progress:(void (^)(NSProgress *))downloadProgress success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter{
    RetriableAFNetworkingRequest *request=[[RetriableAFNetworkingRequest alloc]initWithURLString:URLString parameters:parameters constructingBodyWithBlock:nil uploadProgress:nil downloadProgress:downloadProgress];
    RetriableOperation *operation=[[RetriableOperation alloc]initWithRequest:request retryAfter:retryAfter completion:^(RetriableAFNetworkingResponse *response,NSError *latestError) {
        if(latestError){
            if (failure) failure(response.URLSessionDataTask,latestError);
        }else{
            if (success) success(response.URLSessionDataTask,response.responseObject);
        }
    } isBackgroundTaskEnabled:YES start:^(RetriableAFNetworkingRequest *request,void (^completion)(RetriableAFNetworkingResponse *response,NSError *error)) {
        request.currentURLSessionDataTask=[self GET:request.URLString parameters:request.parameters progress:request.downloadProgress success:^(NSURLSessionDataTask * task,id  responseObject) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:responseObject];
            completion(response,nil);
        } failure:^(NSURLSessionDataTask * task,NSError * error) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:nil];
            completion(response,error);
        }];
    } cancel:^(RetriableAFNetworkingRequest *request) {
        if (!request.currentURLSessionDataTask) return;
        [request.currentURLSessionDataTask cancel];
        [request setCurrentURLSessionDataTask:nil];
    } cancelledErrorTemplates:nil];
    [self.retriable_operationQueue addOperation:operation];
    return nil;
}

- (RetriableOperation*)retriable_POST:(NSString *)URLString parameters:(id)parameters progress:(void (^)(NSProgress *))uploadProgress success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter{
    RetriableAFNetworkingRequest *request=[[RetriableAFNetworkingRequest alloc]initWithURLString:URLString parameters:parameters constructingBodyWithBlock:nil uploadProgress:uploadProgress downloadProgress:nil];
    RetriableOperation *operation=[[RetriableOperation alloc]initWithRequest:request retryAfter:retryAfter completion:^(RetriableAFNetworkingResponse *response,NSError *latestError) {
        if(latestError){
            if (failure) failure(response.URLSessionDataTask,latestError);
        }else{
            if (success) success(response.URLSessionDataTask,response.responseObject);
        }
    } isBackgroundTaskEnabled:YES start:^(RetriableAFNetworkingRequest *request,void (^completion)(RetriableAFNetworkingResponse *response,NSError *error)) {
        request.currentURLSessionDataTask=[self POST:request.URLString parameters:request.parameters progress:request.uploadProgress success:^(NSURLSessionDataTask * task,id  responseObject) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:responseObject];
            completion(response,nil);
        } failure:^(NSURLSessionDataTask * task,NSError * error) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:nil];
            completion(response,error);
        }];
    } cancel:^(RetriableAFNetworkingRequest *request) {
        if (!request.currentURLSessionDataTask) return;
        [request.currentURLSessionDataTask cancel];
        [request setCurrentURLSessionDataTask:nil];
    } cancelledErrorTemplates:nil];
    [self.retriable_operationQueue addOperation:operation];
    return nil;
}

- (RetriableOperation*)retriable_POST:(NSString *)URLString parameters:(id)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block progress:(void (^)(NSProgress *))uploadProgress success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter{
    RetriableAFNetworkingRequest *request=[[RetriableAFNetworkingRequest alloc]initWithURLString:URLString parameters:parameters constructingBodyWithBlock:block uploadProgress:uploadProgress downloadProgress:nil];
    RetriableOperation *operation=[[RetriableOperation alloc]initWithRequest:request retryAfter:retryAfter completion:^(RetriableAFNetworkingResponse *response,NSError *latestError) {
        if(latestError){
            if (failure) failure(response.URLSessionDataTask,latestError);
        }else{
            if (success) success(response.URLSessionDataTask,response.responseObject);
        }
    } isBackgroundTaskEnabled:YES start:^(RetriableAFNetworkingRequest *request,void (^completion)(RetriableAFNetworkingResponse *response,NSError *error)) {
        request.currentURLSessionDataTask=[self POST:request.URLString parameters:request.parameters constructingBodyWithBlock:request.constructingBodyBlock progress:request.uploadProgress success:^(NSURLSessionDataTask * task,id  responseObject) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:responseObject];
            completion(response,nil);
        } failure:^(NSURLSessionDataTask * task,NSError * error) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:nil];
            completion(response,error);
        }];
    } cancel:^(RetriableAFNetworkingRequest *request) {
        if (!request.currentURLSessionDataTask) return;
        [request.currentURLSessionDataTask cancel];
        [request setCurrentURLSessionDataTask:nil];
    } cancelledErrorTemplates:nil];
    [self.retriable_operationQueue addOperation:operation];
    return nil;
}

- (RetriableOperation*)retriable_HEAD:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter{
    RetriableAFNetworkingRequest *request=[[RetriableAFNetworkingRequest alloc]initWithURLString:URLString parameters:parameters constructingBodyWithBlock:nil uploadProgress:nil downloadProgress:nil];
    RetriableOperation *operation=[[RetriableOperation alloc]initWithRequest:request retryAfter:retryAfter completion:^(RetriableAFNetworkingResponse *response,NSError *latestError) {
        if(latestError){
            if (failure) failure(response.URLSessionDataTask,latestError);
        }else{
            if (success) success(response.URLSessionDataTask);
        }
    } isBackgroundTaskEnabled:YES start:^(RetriableAFNetworkingRequest *request,void (^completion)(RetriableAFNetworkingResponse *response,NSError *error)) {
        request.currentURLSessionDataTask=[self HEAD:request.URLString parameters:request.parameters success:^(NSURLSessionDataTask * task) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:nil];
            completion(response,nil);
        } failure:^(NSURLSessionDataTask * task,NSError * error) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:nil];
            completion(response,error);
        }];
    } cancel:^(RetriableAFNetworkingRequest *request) {
        if (!request.currentURLSessionDataTask) return;
        [request.currentURLSessionDataTask cancel];
        [request setCurrentURLSessionDataTask:nil];
    } cancelledErrorTemplates:nil];
    [self.retriable_operationQueue addOperation:operation];
    return nil;
}

- (RetriableOperation*)retriable_PUT:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter{
    RetriableAFNetworkingRequest *request=[[RetriableAFNetworkingRequest alloc]initWithURLString:URLString parameters:parameters constructingBodyWithBlock:nil uploadProgress:nil downloadProgress:nil];
    RetriableOperation *operation=[[RetriableOperation alloc]initWithRequest:request retryAfter:retryAfter completion:^(RetriableAFNetworkingResponse *response,NSError *latestError) {
        if(latestError){
            if (failure) failure(response.URLSessionDataTask,latestError);
        }else{
            if (success) success(response.URLSessionDataTask,response.responseObject);
        }
    } isBackgroundTaskEnabled:YES start:^(RetriableAFNetworkingRequest *request,void (^completion)(RetriableAFNetworkingResponse *response,NSError *error)) {
        request.currentURLSessionDataTask=[self PUT:request.URLString parameters:request.parameters success:^(NSURLSessionDataTask * task,id  responseObject) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:responseObject];
            completion(response,nil);
        } failure:^(NSURLSessionDataTask * task,NSError * error) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:nil];
            completion(response,error);
        }];
    } cancel:^(RetriableAFNetworkingRequest *request) {
        if (!request.currentURLSessionDataTask) return;
        [request.currentURLSessionDataTask cancel];
        [request setCurrentURLSessionDataTask:nil];
    } cancelledErrorTemplates:nil];
    [self.retriable_operationQueue addOperation:operation];
    return nil;
}

- (RetriableOperation*)retriable_PATCH:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter{
    RetriableAFNetworkingRequest *request=[[RetriableAFNetworkingRequest alloc]initWithURLString:URLString parameters:parameters constructingBodyWithBlock:nil uploadProgress:nil downloadProgress:nil];
    RetriableOperation *operation=[[RetriableOperation alloc]initWithRequest:request retryAfter:retryAfter completion:^(RetriableAFNetworkingResponse *response,NSError *latestError) {
        if(latestError){
            if (failure) failure(response.URLSessionDataTask,latestError);
        }else{
            if (success) success(response.URLSessionDataTask,response.responseObject);
        }
    } isBackgroundTaskEnabled:YES start:^(RetriableAFNetworkingRequest *request,void (^completion)(RetriableAFNetworkingResponse *response,NSError *error)) {
        request.currentURLSessionDataTask=[self PATCH:request.URLString parameters:request.parameters success:^(NSURLSessionDataTask * task,id  responseObject) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:responseObject];
            completion(response,nil);
        } failure:^(NSURLSessionDataTask * task,NSError * error) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:nil];
            completion(response,error);
        }];
    } cancel:^(RetriableAFNetworkingRequest *request) {
        if (!request.currentURLSessionDataTask) return;
        [request.currentURLSessionDataTask cancel];
        [request setCurrentURLSessionDataTask:nil];
    } cancelledErrorTemplates:nil];
    [self.retriable_operationQueue addOperation:operation];
    return nil;

}

- (RetriableOperation*)retriable_DELETE:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter{
    RetriableAFNetworkingRequest *request=[[RetriableAFNetworkingRequest alloc]initWithURLString:URLString parameters:parameters constructingBodyWithBlock:nil uploadProgress:nil downloadProgress:nil];
    __weak typeof(self) weakSelf=self;
    RetriableOperation *operation=[[RetriableOperation alloc]initWithRequest:request retryAfter:retryAfter completion:^(RetriableAFNetworkingResponse *response,NSError *latestError) {
        if(latestError){
            if (failure) failure(response.URLSessionDataTask,latestError);
        }else{
            if (success) success(response.URLSessionDataTask,response.responseObject);
        }
    } isBackgroundTaskEnabled:YES start:^(RetriableAFNetworkingRequest *request,void (^completion)(RetriableAFNetworkingResponse *response,NSError *error)) {
        __strong typeof(weakSelf) self=weakSelf;
        request.currentURLSessionDataTask=[self DELETE:request.URLString parameters:request.parameters success:^(NSURLSessionDataTask * task,id  responseObject) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:responseObject];
            completion(response,nil);
        } failure:^(NSURLSessionDataTask * task,NSError * error) {
            RetriableAFNetworkingResponse *response=[[RetriableAFNetworkingResponse alloc]initWithURLSessionDataTask:task responseObject:nil];
            completion(response,error);
        }];
    } cancel:^(RetriableAFNetworkingRequest *request) {
        if (!request.currentURLSessionDataTask) return;
        [request.currentURLSessionDataTask cancel];
        [request setCurrentURLSessionDataTask:nil];
    } cancelledErrorTemplates:nil];
    [self.retriable_operationQueue addOperation:operation];
    return nil;
}

@end
