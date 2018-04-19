//
//  ViewController.m
//  Example
//
//  Created by emsihyo on 2018/4/17.
//  Copyright © 2018年 emsihyo. All rights reserved.
//

@import OOHTTP;

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic,strong)AFHTTPSessionManager *sesssionManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURLSessionConfiguration *cfg=[NSURLSessionConfiguration defaultSessionConfiguration];
    cfg.timeoutIntervalForRequest=2;
    cfg.timeoutIntervalForResource=2;
    self.sesssionManager=[[AFHTTPSessionManager alloc]initWithSessionConfiguration:cfg];
    self.sesssionManager.completionQueue=dispatch_queue_create("session.queue", DISPATCH_QUEUE_SERIAL);
    [self.sesssionManager oo_http_GET:@"https://www.baidu.com" headers:@{@"xxxx-xxxx":@"oooo-oooo"} parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    } retryAfter:^NSTimeInterval(id task, NSInteger currentRetryTime, NSError *latestError) {
        if (![latestError.domain isEqualToString:NSURLErrorDomain]) return 0;
        switch (latestError.code) {
            case NSURLErrorTimedOut:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorNotConnectedToInternet: return 1;
            default: return 0;
        }
    }];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
