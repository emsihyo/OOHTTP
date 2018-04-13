//
//  AFPropertyListRequestSerializer+OOHTTP.m
//  OOHTTP
//
//  Created by emsihyo on 2018/4/13.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <JRSwizzle/JRSwizzle.h>

#import "AFHTTPRequestSerializer+OOHTTP.h"
#import "AFJSONRequestSerializer+OOHTTP.h"

@implementation AFPropertyListRequestSerializer (OOHTTP)
- (NSURLRequest *)oo_http_requestBySerializingRequest:(NSURLRequest *)req withParameters:(nullable id)parameters error:(NSError * _Nullable __autoreleasing *)error{
    NSMutableURLRequest *request=[req mutableCopy];
    NSURL *url;NSDictionary *headers;
    oo_http_parseHeaders(request.URL, self.oo_allHeaders, &url, &headers);
    request.URL=url;
    request=[[self oo_http_requestBySerializingRequest:request withParameters:parameters error:error] mutableCopy];
    return request;
}

+ (void)load{
    [self jr_swizzleMethod:@selector(requestBySerializingRequest:withParameters:error:) withMethod:@selector(oo_http_requestBySerializingRequest:withParameters:error:) error:nil];
}
@end
