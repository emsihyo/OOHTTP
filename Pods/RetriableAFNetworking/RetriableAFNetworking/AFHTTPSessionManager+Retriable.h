//
//  AFHTTPSessionManager+Retriable.h
//  RetriableAFNetworking
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <Retriable/Retriable.h>

@interface AFHTTPSessionManager (Retriable)

@property (readonly) NSOperationQueue *retriable_operationQueue;

- (RetriableOperation*)retriable_GET:(NSString *)URLString parameters:(id)parameters progress:(void (^)(NSProgress *))downloadProgress success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter;

- (RetriableOperation*)retriable_POST:(NSString *)URLString parameters:(id)parameters progress:(void (^)(NSProgress *))uploadProgress success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter;

- (RetriableOperation*)retriable_POST:(NSString *)URLString parameters:(id)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block progress:(void (^)(NSProgress *))uploadProgress success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter;

- (RetriableOperation*)retriable_HEAD:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter;

- (RetriableOperation*)retriable_PUT:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter;

- (RetriableOperation*)retriable_PATCH:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter;

- (RetriableOperation*)retriable_DELETE:(NSString *)URLString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *,id))success failure:(void (^)(NSURLSessionDataTask *,NSError *))failure retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter;

@end
