//
//  OOHTTPTask.h
//  OOHTTP
//
//  Created by emsihyo on 2018/3/29.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

@import AFNetworking;

#import <Foundation/Foundation.h>

#ifndef OOHTTPLogEnabled
#define OOHTTPLogEnabled 0
#endif

typedef NSTimeInterval OOHTTPRetryInterval;

#ifndef OOHTTPRetryDisabled
#define OOHTTPRetryDisabled ((NSTimeInterval)0)
#endif

typedef NS_ENUM(NSInteger,OOHTTPTaskType) {
    OOHTTPTaskTypeGet,
    OOHTTPTaskTypePost,
    OOHTTPTaskTypeHead,
    OOHTTPTaskTypePut,
    OOHTTPTaskTypePatch,
    OOHTTPTaskTypeDelete
};

@interface OOHTTPTask : NSOperation

@property (readonly) NSDictionary     *headers;
@property (readonly) NSDictionary     *parameters;
@property (readonly) NSError          *latestError;
@property (readonly) NSInteger        currentRetryTime;
@property (readonly) NSString         *urlString;
@property (readonly) OOHTTPTaskType   taskType;
@property (readonly) id               responseObject;

@property (readonly) NSTimeInterval   totalDuration;
@property (readonly) NSTimeInterval   latestDuration;

+ (instancetype)GET:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter downloadProgress:(void (^)(NSProgress *progress))downloadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

+ (instancetype)POST:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter constructingBody:(void (^)(id <AFMultipartFormData> formData))constructingBody uploadProgress:(void (^)(NSProgress *progress))uploadProgress completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

+ (instancetype)HEAD:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

+ (instancetype)PUT:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

+ (instancetype)PATCH:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

+ (instancetype)DELETE:(AFHTTPSessionManager*)sessionManager url:(id)url headers:(NSDictionary*)headers parameters:(id)parameters retryAfter:(OOHTTPRetryInterval(^)(OOHTTPTask *task,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(OOHTTPTask *task,id responseObject,NSError* error))completion;

@end
