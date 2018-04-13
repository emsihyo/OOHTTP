//
//  OOHTTPTaskQueue.h
//  OOHTTP
//
//  Created by emsihyo on 2018/3/29.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AFNetworking;

FOUNDATION_EXPORT NSErrorDomain const OOOOHTTPTaskErrorDomain;

NS_ERROR_ENUM(OOOOHTTPTaskErrorDomain){
    OOOOHTTPTaskErrorCancelled = -999,
    OOOOHTTPTaskErrorBadNetwork,
    OOOOHTTPTaskErrorNonNetwork,
    OOOOHTTPTaskErrorClientError,
    OOOOHTTPTaskErrorServerError,
    OOOOHTTPTaskErrorAPIError
};

#ifndef OOHTTPRetryInterval
#define OOHTTPRetryInterval NSTimeInterval
#define HTTRetryDisabled DBL_MAX
#endif

@interface OOHTTPTask : NSOperation

@end

@interface OOHTTPTaskQueue : NSOperationQueue

- (void)addOperation:(NSOperation *)op NS_UNAVAILABLE;

- (void)addOperationWithBlock:(void (^)(void))block NS_UNAVAILABLE;

- (void)addOperations:(NSArray<NSOperation *> *)ops waitUntilFinished:(BOOL)wait NS_UNAVAILABLE;

- (instancetype)initWithHTTPSessionManager:(AFHTTPSessionManager*)sessionManager taskClass:(Class)taskClass NS_DESIGNATED_INITIALIZER; 

- (OOHTTPTask *)POST:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *error))retryAfter constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block progress:(void (^)(NSProgress *uploadProgress))uploadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

@end
