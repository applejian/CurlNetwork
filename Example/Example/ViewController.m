//
//  ViewController.m
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "ViewController.h"

#import "CCCurlConnectionOperation.h"
#import "CCCurlRequest.h"
#import "CCCurlResponse.h"

#import "CCHttpRequest.h"
#import "CCHttpResponse.h"
#import "CCHttpConnectionOperation.h"

#import "CCHttpGetOperation.h"
#import "CCHttpPostOperation.h"

@interface ViewController ()

@property (nonatomic, strong) CCCurlConnectionOperation *con;

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self testCurlConnection];
    NSLog(@"after test curl connection");
    [self testHttpConnection];
    NSLog(@"after test http connection");
    [self testHttpGetConnection];
    NSLog(@"after test http get connection");
    [self testHttpPostConnection];
    NSLog(@"after test http post connection");
    
    _webView = [[UIWebView alloc] init];
    _webView.frame = self.view.bounds;
    [self.view addSubview:_webView];
    
    NSURL *URL = [NSURL URLWithString:@"http://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [_webView loadRequest:request];
    
}

- (void)testCurlConnection
{
    CCCurlRequest *request = [[CCCurlRequest alloc] init];
    CCCurlResponse *response = [[CCCurlResponse alloc] init];
    CCCurlConnectionOperation *con = [[CCCurlConnectionOperation alloc] initWithRequest:request response:response];
    [con setCompletionBlock:^{
        NSLog(@"responseHeader: %@", [[NSString alloc] initWithData:response.responseHeader encoding:NSUTF8StringEncoding]);
        NSLog(@"response: %@", [[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding]);
    }];
    [con start];
}

- (void)testHttpConnection
{
    CCHttpRequest *request = [[CCHttpRequest alloc] init];
    CCHttpResponse *response = [[CCHttpResponse alloc] init];
    CCHttpConnectionOperation *t = [[CCHttpConnectionOperation alloc] initWithRequest:request response:response];
    [t setCompletionBlockWithSuccess:^(CCHttpConnectionOperation *operation, id responseObject) {
        NSLog(@"responseHeader: %@", [[NSString alloc] initWithData:response.responseHeader encoding:NSUTF8StringEncoding]);
        NSLog(@"response: %@", [[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding]);
    } failure:^(CCHttpConnectionOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
    }];
    [[NSOperationQueue currentQueue] addOperation:t];
}

- (void)testHttpGetConnection
{
    CCHttpRequest *request = [[CCHttpRequest alloc] init];
    CCHttpResponse *response = [[CCHttpResponse alloc] init];
    CCHttpGetOperation *t = [[CCHttpGetOperation alloc] initWithRequest:request response:response];
    [t setCompletionBlockWithSuccess:^(CCHttpConnectionOperation *operation, id responseObject) {
        NSLog(@"responseHeader: %@", [[NSString alloc] initWithData:response.responseHeader encoding:NSUTF8StringEncoding]);
        NSLog(@"response: %@", [[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding]);
    } failure:^(CCHttpConnectionOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
    }];
    [[NSOperationQueue currentQueue] addOperation:t];
}

- (void)testHttpPostConnection
{
    CCHttpRequest *request = [[CCHttpRequest alloc] init];
    CCHttpResponse *response = [[CCHttpResponse alloc] init];
    CCHttpPostOperation *t = [[CCHttpPostOperation alloc] initWithRequest:request response:response];
    [t setCompletionBlockWithSuccess:^(CCHttpConnectionOperation *operation, id responseObject) {
        NSLog(@"responseHeader: %@", [[NSString alloc] initWithData:response.responseHeader encoding:NSUTF8StringEncoding]);
        NSLog(@"response: %@", [[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding]);
    } failure:^(CCHttpConnectionOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
    }];
    [[NSOperationQueue currentQueue] addOperation:t];
}

@end
