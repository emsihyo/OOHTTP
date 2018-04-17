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
@property (nonatomic,strong)OOHTTPTask *task;
@property (nonatomic,strong)AFHTTPSessionManager *sesssionManager;
@property (nonatomic,strong)NSOperationQueue *taskQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURLSessionConfiguration *cfg=[NSURLSessionConfiguration defaultSessionConfiguration];
    cfg.timeoutIntervalForRequest=10;
    cfg.timeoutIntervalForResource=10;
    self.sesssionManager=[[AFHTTPSessionManager alloc]initWithSessionConfiguration:cfg];
    self.taskQueue=[[NSOperationQueue alloc]init];
    self.task=[OOHTTPTask GET:self.sesssionManager url:@"https://www.google.com" headers:nil parameters:nil retryAfter:^OOHTTPRetryInterval(OOHTTPTask *task, NSInteger currentRetryTime, NSError *latestError) {
        return 5;
    } downloadProgress:nil completion:^(OOHTTPTask *task, id responseObject, NSError *error) {
        NSLog(@"\nresponse: %@\nerror:%@",responseObject,error);
    }];
    [self.taskQueue addOperation:self.task];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
