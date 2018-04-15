//
//  OOHTTPTaskQueue.h
//  OOHTTP
//
//  Created by emsihyo on 2018/3/29.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

@import AFNetworking;

#import <Foundation/Foundation.h>

#ifndef OOHTTPRetryInterval
#define OOHTTPRetryInterval NSTimeInterval
#define HTTRetryDisabled 0
#endif

@interface OOHTTPTask : NSOperation

@property (readonly) NSString         *urlString;
@property (readonly) NSDictionary     *headers;
@property (readonly) NSDictionary     *parameters;
@property (readonly) NSInteger        currentRetryTime;
@property (readonly) NSError          *latestError;
@property (readonly) id               responseObject;

@end

@interface OOHTTPTaskQueue : NSOperationQueue

- (void)addOperation:(NSOperation *)op NS_UNAVAILABLE;

- (void)addOperationWithBlock:(void (^)(void))block NS_UNAVAILABLE;

- (void)addOperations:(NSArray<NSOperation *> *)ops waitUntilFinished:(BOOL)wait NS_UNAVAILABLE;

- (void)setSuspended:(BOOL)suspended NS_UNAVAILABLE;

- (instancetype)initWithHTTPSessionManager:(AFHTTPSessionManager*)sessionManager taskClass:(Class)taskClass NS_DESIGNATED_INITIALIZER; 

- (OOHTTPTask *)GET:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter   downloadProgress:(void (^)(NSProgress *progress))downloadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

- (OOHTTPTask *)POST:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter constructingBody:(void (^)(id <AFMultipartFormData> formData))constructingBody uploadProgress:(void (^)(NSProgress *progress))uploadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

- (OOHTTPTask *)HEAD:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter  completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

- (OOHTTPTask *)PUT:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

- (OOHTTPTask *)PATCH:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

- (OOHTTPTask *)DELETE:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

@end
