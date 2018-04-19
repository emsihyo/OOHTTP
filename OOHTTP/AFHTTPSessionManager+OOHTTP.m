//
//  AFHTTPSessionManager+OOHTTP.m
//  OOHTTP
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import "AFHTTPRequestSerializer+OOHTTP.h"
#import "AFHTTPSessionManager+OOHTTP.h"

NSString *const oo_http_header_key = @"oo-http-header-key";

void oo_http_encode(NSString *source,NSString **target,NSDictionary *headers){
    *target=source;
    NSURLComponents *components=[NSURLComponents componentsWithString:source];
    if (!components) return;
    if (![headers isKindOfClass:NSDictionary.class]) return;
    NSData *data=[NSJSONSerialization dataWithJSONObject:headers options:0 error:nil];
    if(data.length==0) return;
    NSString *value=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    if(value.length==0) return;
    value=[value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURLQueryItem *item=[NSURLQueryItem queryItemWithName:oo_http_header_key value:value];
    NSMutableArray *queryItems=[components.queryItems mutableCopy];
    queryItems=queryItems?queryItems:[NSMutableArray array];
    [queryItems addObject:item];
    components.queryItems=queryItems;
    *target=components.URL.absoluteString;
}

void oo_http_decode(NSString *source,NSString **target,NSDictionary **headers){
    *target=source;
    NSURLComponents *components=[NSURLComponents componentsWithString:source];
    if (!components) return;
    NSMutableArray *queryItems=[components.queryItems mutableCopy];
    for (NSURLQueryItem *i in queryItems){
        if (![i.name isEqualToString:oo_http_header_key]) continue;
        [queryItems removeObject:i];
        components.queryItems=queryItems;
        *target=components.URL.absoluteString;
        NSDictionary *d=[NSJSONSerialization JSONObjectWithData:[[i.value stringByRemovingPercentEncoding] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        *headers=d;
        return;
    }
}

@implementation AFHTTPSessionManager (OOHTTP)
- (RetriableOperation*)oo_http_GET:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters progress:(void (^)(NSProgress *))downloadProgress success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter{
    NSString *urlWithHeaders;
    oo_http_encode(URLString, &urlWithHeaders, headers);
    return [self retriable_GET:urlWithHeaders parameters:parameters progress:downloadProgress success:success failure:failure retryAfter:retryAfter];
}

- (RetriableOperation*)oo_http_POST:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters progress:(void (^)(NSProgress *))uploadProgress success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter{
    NSString *urlWithHeaders;
    oo_http_encode(URLString, &urlWithHeaders, headers);
    return [self retriable_POST:urlWithHeaders parameters:parameters progress:uploadProgress success:success failure:failure retryAfter:retryAfter];
}

- (RetriableOperation*)oo_http_POST:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block progress:(void (^)(NSProgress *))uploadProgress success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter{
    NSString *urlWithHeaders;
    oo_http_encode(URLString, &urlWithHeaders, headers);
    return [self retriable_POST:urlWithHeaders parameters:parameters constructingBodyWithBlock:block progress:uploadProgress success:success failure:failure retryAfter:retryAfter];
}

- (RetriableOperation*)oo_http_HEAD:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter{
    NSString *urlWithHeaders;
    oo_http_encode(URLString, &urlWithHeaders, headers);
    return [self retriable_HEAD:urlWithHeaders parameters:parameters success:success failure:failure retryAfter:retryAfter];
}

- (RetriableOperation*)oo_http_PUT:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter{
    NSString *urlWithHeaders;
    oo_http_encode(URLString, &urlWithHeaders, headers);
    return [self retriable_PUT:urlWithHeaders parameters:parameters success:success failure:failure retryAfter:retryAfter];
}

- (RetriableOperation*)oo_http_PATCH:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter{
    NSString *urlWithHeaders;
    oo_http_encode(URLString, &urlWithHeaders, headers);
    return [self retriable_PATCH:urlWithHeaders parameters:parameters success:success failure:failure retryAfter:retryAfter];
}

- (RetriableOperation*)oo_http_DELETE:(NSString *)URLString headers:(NSDictionary*)headers parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure retryAfter:(NSTimeInterval (^)(id, NSInteger, NSError *))retryAfter{
    NSString *urlWithHeaders;
    oo_http_encode(URLString, &urlWithHeaders, headers);
    return [self retriable_DELETE:urlWithHeaders parameters:parameters success:success failure:failure retryAfter:retryAfter];
}

@end
