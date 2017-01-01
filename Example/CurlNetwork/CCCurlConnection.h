//
//  CCCurlConnection.h
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCHttpClient;
@class CCHttpRequest;
@class CCHttpResponse;

@interface CCCurlConnection : NSObject

- (instancetype)initWithHttpClient:(CCHttpClient *)aClient httpRequest:(CCHttpRequest *)aRequest httpResponse:(CCHttpResponse *)aResponse;

- (void)start;
- (void)stop;

@end
