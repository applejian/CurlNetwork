//
//  CCCurlRequest.m
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCCurlRequest.h"

@implementation CCCurlRequest

- (instancetype)init
{
    if (self = [super init]) {
        _url = @"https://www.baidu.com";
        _timeoutForConnect = 30;
        _timeoutForRead = 30;
    }
    return self;
}

@end
