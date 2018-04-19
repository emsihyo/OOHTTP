//
//  AFHTTPSessionManager+OOHTTP.h
//  OOHTTP
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <RetriableAFNetworking/RetriableAFNetworking.h>

extern NSString *const oo_http_header_key;

void oo_http_encode(NSString *source,NSString **target,NSDictionary *headers);
void oo_http_decode(NSString *source,NSString **target,NSDictionary **headers);

@interface AFHTTPSessionManager (OOHTTP)

- (RetriableOperation*)oo_http_GET:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters progress:(void (^)(NSProgress *))downloadProgress success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter;

- (RetriableOperation*)oo_http_POST:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters progress:(void (^)(NSProgress *))uploadProgress success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter;

- (RetriableOperation*)oo_http_POST:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block progress:(void (^)(NSProgress *))uploadProgress success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter;

- (RetriableOperation*)oo_http_HEAD:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter;

- (RetriableOperation*)oo_http_PUT:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter;

- (RetriableOperation*)oo_http_PATCH:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter;

- (RetriableOperation*)oo_http_DELETE:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter;

@end
