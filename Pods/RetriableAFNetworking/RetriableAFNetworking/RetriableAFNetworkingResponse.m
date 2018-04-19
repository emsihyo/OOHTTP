//
//  RetriableAFNetworkingResponse.m
//  RetriableAFNetworking
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import "RetriableAFNetworkingResponse.h"

@interface RetriableAFNetworkingResponse()

@property (nonatomic,strong) NSURLSessionDataTask *URLSessionDataTask;
@property (nonatomic,strong) id                   responseObject;

@end

@implementation RetriableAFNetworkingResponse

- (instancetype)initWithURLSessionDataTask:(NSURLSessionDataTask*)URLSessionDataTask responseObject:(id)responseObject{
    self=[self init];
    if (!self) return nil;
    self.URLSessionDataTask=URLSessionDataTask;
    self.responseObject=responseObject;
    return self;
}

@end
