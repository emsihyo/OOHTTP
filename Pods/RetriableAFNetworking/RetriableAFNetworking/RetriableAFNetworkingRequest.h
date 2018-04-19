//
//  RetriableAFNetworkingRequest.h
//  RetriableAFNetworking
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <Foundation/Foundation.h>

@interface RetriableAFNetworkingRequest : NSObject

@property (readonly) NSString             *URLString;
@property (readonly) NSDictionary         *parameters;
@property (readonly) NSURLSessionDataTask *currentURLSessionDataTask;

- (instancetype)initWithURLString:(NSString*)URLString parameters:(NSDictionary*)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block uploadProgress:(void (^)(NSProgress *))uploadProgress downloadProgress:(void (^)(NSProgress *))downloadProgress;

@end
