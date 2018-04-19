//
//  RetriableAFNetworkingRequest+Private.h
//  RetriableAFNetworking
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import "RetriableAFNetworkingRequest.h"

@interface RetriableAFNetworkingRequest (Private)

@property (readonly) void (^constructingBodyBlock)(id<AFMultipartFormData>);
@property (readonly) void (^uploadProgress)(NSProgress * progress);
@property (readonly) void (^downloadProgress)(NSProgress * progress);

- (void)setCurrentURLSessionDataTask:(NSURLSessionDataTask *)currentURLSessionDataTask;

@end
