//
//  OODataHTTPResponseSerializer.m
//  OOHTTP
//
//  Created by emsihyo on 2018/4/12.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

#import "OODataHTTPResponseSerializer.h"

@implementation OODataHTTPResponseSerializer

- (nullable id)responseObjectForResponse:(nullable NSHTTPURLResponse *)response data:(nullable NSData *)data error:(NSError * _Nullable __autoreleasing *)error{
    if (response.statusCode!=200) {
       if(error) *error=[NSError errorWithDomain:AFURLResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSURLErrorKey:response.URL?response.URL:NSNull.null}];
        return nil;
    }
    return data;
}

@end
