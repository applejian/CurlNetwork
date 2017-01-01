//
//  ViewController.m
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "ViewController.h"
#import "CCHttpClient.h"

@interface ViewController ()

@property (nonatomic, strong) CCHttpClient *client;

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _client = [[CCHttpClient alloc] init];
    [_client doTest];
    
    _webView = [[UIWebView alloc] init];
    _webView.frame = self.view.bounds;
    [self.view addSubview:_webView];
    
    NSURL *URL = [NSURL URLWithString:@"http://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [_webView loadRequest:request];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
