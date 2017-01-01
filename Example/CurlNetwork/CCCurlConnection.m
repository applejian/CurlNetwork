//
//  CCCurlConnection.m
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCCurlConnection.h"
#import <curl.h>
#import "CCHttpClient.h"
#import "CCHttpRequest.h"
#import "CCHttpResponse.h"

static NSString *CCCurlConnectionDomain = @"CCCurlConnectionDomain";

// Callback function used by libcurl for collect response data
static size_t writeData(void *ptr, size_t size, size_t nmemb, void *stream)
{
    CCHttpResponse *response = (__bridge CCHttpResponse *)(stream);
    size_t sizes = size * nmemb;
    
    // add data to the end of recvBuffer
    // write data maybe called more than once in a single request
    [response.responseData appendBytes:ptr length:sizes];
    
    NSLog(@"writeData: %zu", sizes);
    return sizes;
}

// Callback function used by libcurl for collect header data
static size_t writeHeaderData(void *ptr, size_t size, size_t nmemb, void *stream)
{
    CCHttpResponse *response = (__bridge CCHttpResponse *)(stream);
    size_t sizes = size * nmemb;
    
    // add data to the end of recvBuffer
    // write data maybe called more than once in a single request
    [response.responseHeader appendBytes:ptr length:sizes];
    
    NSLog(@"writeHeaderData: %zu", sizes);
    return sizes;
}

@interface CCCurlConnection ()
{
    //Instance of CURL
    CURL *_curl;
}

@property (nonatomic, strong) CCHttpClient *client;
@property (nonatomic, strong) CCHttpRequest *request;
@property (nonatomic, strong) CCHttpResponse *response;

@end

@implementation CCCurlConnection

+ (void)load
{
    curl_global_init(CURL_GLOBAL_ALL);
}

- (void)dealloc
{
    curl_easy_cleanup(_curl);
}

- (BOOL)configureCURL
{
    CURL *handle = _curl;
    
    if (!handle) {
        return NO;
    }
    
    char *errorBuffer;
    CURLcode code = curl_easy_setopt(handle, CURLOPT_ERRORBUFFER, errorBuffer);
    if (CURLE_OK != code) {
        return NO;
    }
    
    code = curl_easy_setopt(handle, CURLOPT_TIMEOUT, _request.timeoutForRead);
    if (CURLE_OK != code) {
        return NO;
    }
    
    code = curl_easy_setopt(handle, CURLOPT_CONNECTTIMEOUT, _request.timeoutForConnect);
    if (CURLE_OK != code) {
        return NO;
    }
    
    if (_client.sslCaFilename.length == 0) {
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYPEER, 0L);
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYHOST, 0L);
    } else {
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYPEER, 1L);
        curl_easy_setopt(handle, CURLOPT_SSL_VERIFYHOST, 2L);
        curl_easy_setopt(handle, CURLOPT_CAINFO, [_client.sslCaFilename UTF8String]);
    }
    
    // FIXED #3224: The subthread of CCHttpClient interrupts main thread if timeout comes.
    // Document is here: http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTNOSIGNAL
    curl_easy_setopt(handle, CURLOPT_NOSIGNAL, 1L);
    
    curl_easy_setopt(handle, CURLOPT_ACCEPT_ENCODING, "");
    
    return YES;
}

- (instancetype)initWithHttpClient:(CCHttpClient *)aClient httpRequest:(CCHttpRequest *)aRequest httpResponse:(CCHttpResponse *)aResponse
{
    if (self = [super init]) {
        _curl = curl_easy_init();
        _client = aClient;
        _request = aRequest;
        _response = aResponse;
    }
    return self;
}

- (BOOL)setOption:(CURLoption)option data:(id)data
{
//    CURLcode code = curl_easy_setopt(_curl, option, data);
    
    return YES;
}

- (BOOL)performWithError:(NSError **)outError
{
    CURLcode code = curl_easy_perform(_curl);
    if (CURLE_OK != code) {
        NSDictionary *userInfo = @{ @"msg": @"Curl curl_easy_perform failed." };
        *outError = [NSError errorWithDomain:CCCurlConnectionDomain code:code userInfo:userInfo];
        return NO;
    }
    
    long responseCode = -1;
    code = curl_easy_getinfo(_curl, CURLINFO_RESPONSE_CODE, &responseCode);
    if (CURLE_OK != code || !(responseCode >= 200 && responseCode < 300)) {
        NSString *msg = [NSString stringWithFormat:@"Curl curl_easy_getinfo failed: %s", curl_easy_strerror(code)];
        NSDictionary *userInfo = @{ @"msg": msg };
        *outError = [NSError errorWithDomain:CCCurlConnectionDomain code:code userInfo:userInfo];
        return NO;
    }
    return YES;
}

- (NSInteger)processGetTaskWithError:(NSError **)outError
{
    CURLcode code = curl_easy_setopt(_curl, CURLOPT_FOLLOWLOCATION, true);
    if (CURLE_OK != code) {
        NSString *msg = [NSString stringWithFormat:@"Curl curl_easy_setopt failed: %s", curl_easy_strerror(code)];
        NSDictionary *userInfo = @{ @"msg": msg };
        *outError = [NSError errorWithDomain:CCCurlConnectionDomain code:code userInfo:userInfo];
        return code;
    }
    
    return [self performWithError:outError];
}

- (void)start
{
    CURLcode code = 0;
    
    [self configureCURL];
    
    /* get custom header data (if set) */
    struct curl_slist *headers = NULL;
    NSArray *headerValues = [_request.headers allValues];
    /* append custom headers one by one */
    for (NSString *item in headerValues) {
        headers = curl_slist_append(headers, [item UTF8String]);
    }
    /* set custom headers for curl */
    code = curl_easy_setopt(_curl, CURLOPT_HTTPHEADER, headers);
    if (CURLE_OK != code) {
        return;
    }
    
    /* get cookie file */
    if (_client.cookieFilename.length > 0) {
        code = curl_easy_setopt(_curl, CURLOPT_COOKIEFILE, [_client.cookieFilename UTF8String]);
        code = curl_easy_setopt(_curl, CURLOPT_COOKIEJAR, [_client.cookieFilename UTF8String]);
    }
    
    code = curl_easy_setopt(_curl, CURLOPT_URL, [_request.url UTF8String]);
    code = curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, writeData);
    code = curl_easy_setopt(_curl, CURLOPT_WRITEDATA, _response);
    code = curl_easy_setopt(_curl, CURLOPT_HEADERFUNCTION, writeHeaderData);
    code = curl_easy_setopt(_curl, CURLOPT_HEADERDATA, _response);
    
    //
    code = curl_easy_setopt(_curl, CURLOPT_FOLLOWLOCATION, true);
    
    NSError *error;
    code = curl_easy_perform(_curl);
    if (CURLE_OK != code) {
        NSDictionary *userInfo = @{ @"msg": @"Curl curl_easy_perform failed." };
        error = [NSError errorWithDomain:CCCurlConnectionDomain code:code userInfo:userInfo];
        return;
    }
    
    long responseCode = -1;
    code = curl_easy_getinfo(_curl, CURLINFO_RESPONSE_CODE, &responseCode);
    if (CURLE_OK != code || !(responseCode >= 200 && responseCode < 300)) {
        NSString *msg = [NSString stringWithFormat:@"Curl curl_easy_getinfo failed: %s", curl_easy_strerror(code)];
        NSDictionary *userInfo = @{ @"msg": msg };
        error = [NSError errorWithDomain:CCCurlConnectionDomain code:code userInfo:userInfo];
        return;
    }
    NSLog(@"responseCode: %ld", responseCode);
}

- (void)stop
{}

@end
