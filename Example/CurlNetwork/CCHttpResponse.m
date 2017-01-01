//
//  CCHttpResponse.m
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCHttpResponse.h"

@implementation CCHttpResponse

- (NSMutableData *)responseData
{
    if (nil == _responseData) {
        _responseData = [[NSMutableData alloc] init];
    }
    return _responseData;
}

- (NSMutableData *)responseHeader
{
    if (nil == _responseHeader) {
        _responseHeader = [[NSMutableData alloc] init];
    }
    return _responseHeader;
}

@end
