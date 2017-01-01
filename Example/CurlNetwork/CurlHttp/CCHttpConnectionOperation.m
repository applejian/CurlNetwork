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

- (BOOL)configureCURL
{
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
    code = curl_easy_setopt(self.curl, CURLOPT_HTTPHEADER, headers);
    if (CURLE_OK != code) {
        self.error = [self errorWithCode:code];
        return NO;
    }
    
    /* get cookie file */
    if (self.cookieFilename.length > 0) {
        code = curl_easy_setopt(self.curl, CURLOPT_COOKIEFILE, [self.cookieFilename UTF8String]);
        code = curl_easy_setopt(self.curl, CURLOPT_COOKIEJAR, [self.cookieFilename UTF8String]);
    }
    
    /* get ca file for ssl */
    if (self.sslCaFilename.length == 0) {
        curl_easy_setopt(self.curl, CURLOPT_SSL_VERIFYPEER, 0L);
        curl_easy_setopt(self.curl, CURLOPT_SSL_VERIFYHOST, 0L);
    } else {
        curl_easy_setopt(self.curl, CURLOPT_SSL_VERIFYPEER, 1L);
        curl_easy_setopt(self.curl, CURLOPT_SSL_VERIFYHOST, 2L);
        curl_easy_setopt(self.curl, CURLOPT_CAINFO, [self.sslCaFilename UTF8String]);
    }
    
    // FIXED #3224: The subthread of CCHttpClient interrupts main thread if timeout comes.
    // Document is here: http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTNOSIGNAL
    curl_easy_setopt(self.curl, CURLOPT_NOSIGNAL, 1L);
    
//    curl_easy_setopt(self.curl, CURLOPT_ACCEPT_ENCODING, "");//? result failed
    
    return [super configureCURL];
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
                /*
                long responseCode = -1;
                curl_easy_getinfo(self.curl, CURLINFO_RESPONSE_CODE, &responseCode);
                if (responseCode < 200 || responseCode >= 300) {
                    self.error = [NSError errorWithDomain:NSURLErrorDomain code:responseCode userInfo:nil];
                }
                
                CCHttpResponse *response = (CCHttpResponse *)self.response;
                response.responseCode = responseCode;
                */
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
