//
//  CCHttpConnectionOperation.m
//  Example
//
//  Created by zhuruhong on 2017/1/2.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCHttpConnectionOperation.h"
#import "CCHttpRequest.h"
#import "CCHttpResponse.h"

static dispatch_queue_t http_request_operation_processing_queue() {
    static dispatch_queue_t cc_http_request_operation_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cc_http_request_operation_processing_queue = dispatch_queue_create("com.curl.networking.http-request.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return cc_http_request_operation_processing_queue;
}

static dispatch_group_t http_request_operation_completion_group() {
    static dispatch_group_t cc_http_request_operation_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cc_http_request_operation_completion_group = dispatch_group_create();
    });
    
    return cc_http_request_operation_completion_group;
}

@implementation CCHttpConnectionOperation

- (void)curlWillPerform:(CURL *)handle
{
    [super curlWillPerform:handle];
    
    CCHttpRequest *request = (CCHttpRequest *)self.request;
    CURLcode code;
    
    /* get custom header data (if set) */
    struct curl_slist *headers = NULL;
    NSArray *headerValues = [request.headers allValues];
    /* append custom headers one by one */
    for (NSString *item in headerValues) {
        headers = curl_slist_append(headers, [item UTF8String]);
    }
    /* set custom headers for curl */
    code = curl_easy_setopt(handle, CURLOPT_HTTPHEADER, headers);
    if (CURLE_OK != code) {
        self.error = [self errorWithCode:code];
    }
    
    /* get cookie file */
    if (self.cookieFilename.length > 0) {
        code = curl_easy_setopt(handle, CURLOPT_COOKIEFILE, [self.cookieFilename UTF8String]);
        code = curl_easy_setopt(handle, CURLOPT_COOKIEJAR, [self.cookieFilename UTF8String]);
    }
    
    /* get ca file for ssl */
    if (self.sslCaFilename.length == 0) {
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYPEER, 0L);
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYHOST, 0L);
    } else {
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYPEER, 1L);
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYHOST, 2L);
        curl_easy_setopt(handle, CURLOPT_CAINFO, [self.sslCaFilename UTF8String]);
    }
    
    // FIXED #3224: The subthread of CCHttpClient interrupts main thread if timeout comes.
    // Document is here: http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTNOSIGNAL
    curl_easy_setopt(handle, CURLOPT_NOSIGNAL, 1L);
    
    curl_easy_setopt(handle, CURLOPT_ACCEPT_ENCODING, "gzip");
}

- (void)curlDidPerform:(CURL *)handle
{
    [super curlDidPerform:handle];
    
    CCHttpResponse *response = (CCHttpResponse *)self.response;
    long responseCode = -1;
    CURLcode code;
    
    code = curl_easy_getinfo(handle, CURLINFO_RESPONSE_CODE, &responseCode);
    if (code != CURLE_OK) {
        self.error = [self errorWithCode:code];
        return;
    }
    
    response.responseCode = responseCode;
    if (!(responseCode >= 200 && responseCode < 300)) {
        NSString *msg = [NSString stringWithFormat:@"%s", curl_easy_strerror(code)];
        NSDictionary *userInfo = @{ @"msg": msg };
        self.error = [NSError errorWithDomain:NSURLErrorDomain code:responseCode userInfo:userInfo];
        return;
    }
}

- (void)setCompletionBlockWithSuccess:(void (^)(CCHttpConnectionOperation *operation, id responseObject))success failure:(void (^)(CCHttpConnectionOperation *operation, NSError *error))failure
{
    // completionBlock is manually nilled out in AFURLConnectionOperation to break the retain cycle.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
#pragma clang diagnostic ignored "-Wgnu"
    self.completionBlock = ^{
        if (self.completionGroup) {
            dispatch_group_enter(self.completionGroup);
        }
        
        dispatch_async(http_request_operation_processing_queue(), ^{
            if (self.error) {
                if (failure) {
                    dispatch_group_async(self.completionGroup ?: http_request_operation_completion_group(), self.completionQueue ?: dispatch_get_main_queue(), ^{
                        failure(self, self.error);
                    });
                }
            } else {
                id responseObject = self.responseObject;
                if (self.error) {
                    if (failure) {
                        dispatch_group_async(self.completionGroup ?: http_request_operation_completion_group(), self.completionQueue ?: dispatch_get_main_queue(), ^{
                            failure(self, self.error);
                        });
                    }
                } else {
                    if (success) {
                        dispatch_group_async(self.completionGroup ?: http_request_operation_completion_group(), self.completionQueue ?: dispatch_get_main_queue(), ^{
                            success(self, responseObject);
                        });
                    }
                }
            }
            
            if (self.completionGroup) {
                dispatch_group_leave(self.completionGroup);
            }
        });
    };
#pragma clang diagnostic pop
}

@end
