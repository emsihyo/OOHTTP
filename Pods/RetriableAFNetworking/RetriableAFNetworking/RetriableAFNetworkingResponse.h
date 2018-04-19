//
//  RetriableAFNetworkingResponse.h
//  RetriableAFNetworking
//
//  Created by emsihyo on 2018/4/19.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RetriableAFNetworkingResponse : NSObject

@property (readonly) NSURLSessionDataTask *URLSessionDataTask;
@property (readonly) id                   responseObject;

- (instancetype)initWithURLSessionDataTask:(NSURLSessionDataTask*)URLSessionDataTask responseObject:(id)responseObject;

@end
