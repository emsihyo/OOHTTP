//
//  OODataHTTPRequestSerializer.m
//  OOHTTP
//
//  Created by emsihyo on 2018/4/12.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import "OODataHTTPRequestSerializer.h"

@implementation OODataHTTPRequestSerializer

- (nullable NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(nullable id)parameters error:(NSError * _Nullable __autoreleasing *)error {
    if(!request.URL){
        if (error) *error=[NSError errorWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:nil];
        return nil;
    }
    return request;
}

@end
