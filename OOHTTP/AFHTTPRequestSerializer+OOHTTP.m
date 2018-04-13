//
//  AFHTTPRequestSerializer+OOHTTP.m
//  OOHTTP
//
//  Created by emsihyo on 2018/4/13.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import "AFHTTPRequestSerializer+OOHTTP.h"

void oo_http_parseHeaders(id source,NSDictionary *allHeaders,NSURL **targetUrl,NSDictionary **targetHeaders) {
    NSURL *url;
   if([source isKindOfClass:NSURL.class]){
        url=source;
    }else if([source isKindOfClass:NSString.class]){
        url=[NSURL URLWithString:source];
    }else{
        NSCParameterAssert(0);
    }
    NSURLComponents *urlComponents=[NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];;
    NSDictionary *headers;
    *targetUrl=url;
    for (NSURLQueryItem *item in urlComponents.queryItems){
        if ([item.name isEqualToString:oo_http_header_key]) {
            headers=allHeaders[item.value];
            NSMutableArray *items=[urlComponents.queryItems mutableCopy];
            [items removeObject:item];
            urlComponents.queryItems=items;
            *targetUrl=[urlComponents URL];
            *targetHeaders=headers;
            return;
        }
    }
}

NSString *const oo_http_header_key = @"oo-http-header-key";

@import JRSwizzle;

@implementation AFHTTPRequestSerializer (OOHTTP)

- (NSDictionary*)oo_http_headers{
    id headers=objc_getAssociatedObject(self, @selector(oo_http_headers));
    if (!headers){
        headers=[NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @selector(oo_http_headers), headers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return headers;
}
- (NSDictionary*)oo_allHeaders{
    return [self oo_http_headers];
}
- (NSDictionary*)oo_http_httpHeadersForKey:(NSString*)key{
    @synchronized (self){
        return [self oo_http_headers][key];
    }
}

- (void)oo_http_setHTTPHeaders:(NSDictionary*)headers forKey:(NSString*)key{
    @synchronized (self) {
        NSMutableDictionary *m=(NSMutableDictionary*)self.oo_http_headers;
        if (key&&headers) m[key]=headers;
    }
}

- (void)oo_http_removeHTTPHeadersForKey:(NSString*)key{
    @synchronized (self){
        NSMutableDictionary *m=(NSMutableDictionary*)self.oo_http_headers;
        m[key]=nil;
    }
}

- (NSURLRequest *)oo_http_requestBySerializingRequest:(NSURLRequest *)req withParameters:(nullable id)parameters error:(NSError * _Nullable __autoreleasing *)error{
    NSMutableURLRequest *request=[req mutableCopy];
    NSURL *url;NSDictionary *headers;
    oo_http_parseHeaders(request.URL, [self oo_http_headers], &url, &headers);
    request.URL=url;
    request=[[self oo_http_requestBySerializingRequest:request withParameters:parameters error:error] mutableCopy];
    [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    return request;
}

+ (void)load{
    [self jr_swizzleMethod:@selector(requestBySerializingRequest:withParameters:error:) withMethod:@selector(oo_http_requestBySerializingRequest:withParameters:error:) error:nil];
}

@end
