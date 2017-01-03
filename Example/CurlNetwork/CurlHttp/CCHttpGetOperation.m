//
//  CCHttpGetOperation.m
//  Example
//
//  Created by zhuruhong on 2017/1/3.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCHttpGetOperation.h"

@implementation CCHttpGetOperation

- (void)curlWillPerform:(CURL *)handle
{
    [super curlWillPerform:handle];
    
    curl_easy_setopt(handle, CURLOPT_FOLLOWLOCATION, true);
}

@end
