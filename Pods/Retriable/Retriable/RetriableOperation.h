//
//  RetriableOperation.h
//  Retriable
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RetriableOperation : NSOperation

@property (readonly) id        request;
@property (readonly) id        response;
@property (readonly) NSInteger currentRetryTime;
@property (readonly) NSError   *latestError;

/**
 puase or resume operation.
 */
@property (nonatomic,assign) BOOL isPaused;

/**
 init a operation.

 @param request optional, request context used in the following blocks as arguments. default nil.
 @param retryAfter optional, a block returns interval for next retry, if 0, do not retry. default nil.
 @param completion optional, a block executed when task did completed. default nil.
 @param isBackgroundTaskEnabled is background task enabled. default NO.
 @param start required, a block to start task.
 @param cancel required, a block to cancel task.
 @param cancelledErrorTemplates optional, error teimplates of canncelled error. default @[[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]].
 @return operation
 */
- (instancetype)initWithRequest:(id)request retryAfter:(NSTimeInterval(^)(id request,NSInteger currentRetryTime,NSError *latestError))retryAfter completion:(void(^)(id response,NSError *latestError))completion isBackgroundTaskEnabled:(BOOL)isBackgroundTaskEnabled start:(void(^)(id request,void(^completion)(id response,NSError *error)))start cancel:(void(^)(id request))cancel cancelledErrorTemplates:(NSArray<NSError*>*)cancelledErrorTemplates;

@end
