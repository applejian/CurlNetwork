//
//  CCHttpPostOperation.m
//  Example
//
//  Created by zhuruhong on 2017/1/3.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCHttpPostOperation.h"
#import "CCHttpRequest.h"

@implementation CCHttpPostOperation

- (void)curlWillPerform:(CURL *)handle
{
    [super curlWillPerform:handle];
    
    CCHttpRequest *request = (CCHttpRequest *)self.request;
    
    curl_easy_setopt(handle, CURLOPT_POST, 1);
    curl_easy_setopt(handle, CURLOPT_POSTFIELDS, request.requestData);
    curl_easy_setopt(handle, CURLOPT_POSTFIELDSIZE, request.requestData.length);
    curl_easy_setopt(handle, CURLOPT_FOLLOWLOCATION, true);
}

@end
