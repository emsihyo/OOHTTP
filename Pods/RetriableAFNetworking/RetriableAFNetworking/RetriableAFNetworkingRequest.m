//
//  RetriableAFNetworkingRequest.m
//  RetriableAFNetworking
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "RetriableAFNetworkingRequest.h"

@interface RetriableAFNetworkingRequest ()

@property (nonatomic,strong) NSString             *URLString;
@property (nonatomic,strong) NSDictionary         *parameters;
@property (nonatomic,strong) NSURLSessionDataTask *currentURLSessionDataTask;

@property (nonatomic,strong) void (^constructingBodyBlock)(id<AFMultipartFormData>);
@property (nonatomic,strong) void (^uploadProgress)(NSProgress * progress);
@property (nonatomic,strong) void (^downloadProgress)(NSProgress * progress);

@end

@implementation RetriableAFNetworkingRequest

- (instancetype)initWithURLString:(NSString*)URLString parameters:(NSDictionary*)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block uploadProgress:(void (^)(NSProgress *))uploadProgress downloadProgress:(void (^)(NSProgress *))downloadProgress{
    self=[self init];
    if (!self) return nil;
    self.URLString=URLString;
    self.parameters=parameters;
    self.constructingBodyBlock = block;
    self.uploadProgress = uploadProgress;
    self.downloadProgress = downloadProgress;
    return self;
}

@end
