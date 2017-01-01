//
//  CCHttpClient.m
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCHttpClient.h"
#import "CCCurlConnection.h"
#import "CCHttpRequest.h"
#import "CCHttpResponse.h"

@implementation CCHttpClient

- (void)doTest
{
    CCHttpRequest *request = [[CCHttpRequest alloc] init];
    request.url = @"http://www.baidu.com";
    CCHttpResponse *response = [[CCHttpResponse alloc] init];
    _con = [[CCCurlConnection alloc] initWithHttpClient:self httpRequest:request httpResponse:response];
    [_con start];
}

@end
