//
//  CCHttpRequest.m
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCHttpRequest.h"

@implementation CCHttpRequest

- (instancetype)init
{
    if (self = [super init]) {
        _requestType = CCHttpRequestTypeGet;
        self.url = @"http://www.baidu.com";
    }
    return self;
}

@end
