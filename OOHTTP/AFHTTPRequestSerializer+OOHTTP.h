//
//  AFHTTPRequestSerializer+OOHTTP.h
//  OOHTTP
//
//  Created by emsihyo on 2018/4/13.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

extern NSString *const oo_http_header_key;

void oo_http_parseHeaders(id source,NSDictionary *allHeaders,NSURL **targetUrl,NSDictionary **targetHeaders);

@interface AFHTTPRequestSerializer (OOHTTP)

- (NSDictionary*)oo_allHeaders;

- (NSDictionary*)oo_http_httpHeadersForKey:(NSString*)key;

- (void)oo_http_setHTTPHeaders:(NSDictionary*)headers forKey:(NSString*)key;

- (void)oo_http_removeHTTPHeadersForKey:(NSString*)key;

@end
