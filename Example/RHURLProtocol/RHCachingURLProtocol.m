//
//  RHCachingURLProtocol.m
//  Example
//
//  Created by zhuruhong on 2016/12/31.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import "RHCachingURLProtocol.h"
#import "Reachability.h"
#import "NSString+Crypto.h"
#import "RHCacheData.h"

static NSObject *RHCachingSupportedSchemesMonitor;
static NSSet *RHCachingSupportedSchemes;

static NSString *RHCachingURLHeaderKey = @"RHCachingURLHeaderKey";

@interface RHCachingURLProtocol () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;

- (void)appendData:(NSData *)newData;

@end

@implementation RHCachingURLProtocol

+ (void)initialize {
    if (self == [RHCachingURLProtocol class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            RHCachingSupportedSchemesMonitor = [NSObject new];
        });
        [self setSupportedSchemes:[NSSet setWithObject:@"http"]];
    }
}

+ (NSSet *)supportedSchemes {
    NSSet *supportedSchemes;
    @synchronized(RHCachingSupportedSchemesMonitor) {
        supportedSchemes = RHCachingSupportedSchemes;
    }
    return supportedSchemes;
}

+ (void)setSupportedSchemes:(NSSet *)supportedSchemes {
    @synchronized(RHCachingSupportedSchemesMonitor) {
        RHCachingSupportedSchemes = supportedSchemes;
    }
}

- (BOOL)isUseCache
{
    BOOL reachable = (BOOL) [[Reachability reachabilityWithHostName:[[[self request] URL] host]] currentReachabilityStatus] != NotReachable;
    return !reachable;
}

- (NSString *)cachePathForRequest:(NSURLRequest *)aRequest
{
    // This stores in the Caches directory, which can be deleted when space is low, but we only use it for offline access
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = [[[aRequest URL] absoluteString] sha1];
    
    return [cachesPath stringByAppendingPathComponent:fileName];
}

/*======================================================================
 Begin responsibilities for protocol implementors
 
 The methods between this set of begin-end markers must be
 implemented in order to create a working protocol.
 ======================================================================*/

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // only handle http requests we haven't marked with our header.
    if ([[self supportedSchemes] containsObject:[[request URL] scheme]] &&
        ([request valueForHTTPHeaderField:RHCachingURLHeaderKey] == nil))
    {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    if ([self isUseCache]) {
        RHCacheData *cache = [NSKeyedUnarchiver unarchiveObjectWithFile:[self cachePathForRequest:[self request]]];
        if (cache) {
            NSData *data = [cache data];
            NSURLResponse *response = [cache response];
            NSURLRequest *redirectRequest = [cache redirectRequest];
            if (redirectRequest) {
                [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
            } else {
                // we handle caching ourselves.
                [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                [[self client] URLProtocol:self didLoadData:data];
                [[self client] URLProtocolDidFinishLoading:self];
            }
        }
        else {
            [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
        }
        
        return;
    }
    
    NSMutableURLRequest *connectionRequest =
#if WORKAROUND_MUTABLE_COPY_LEAK
    [[self request] mutableCopyWorkaround];
#else
    [[self request] mutableCopy];
#endif
    // we need to mark this request with our header so we know not to handle it in +[NSURLProtocol canInitWithRequest:].
    [connectionRequest setValue:@"" forHTTPHeaderField:RHCachingURLHeaderKey];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:connectionRequest
                                                                delegate:self];
    [self setConnection:connection];
}

- (void)stopLoading
{
    [[self connection] cancel];
}

/*======================================================================
 End responsibilities for protocol implementors
 ======================================================================*/

// NSURLConnection delegates (generally we pass these on to our client)

- (void)appendData:(NSData *)newData
{
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    }
    else {
        [[self data] appendData:newData];
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
    [self setConnection:nil];
    [self setData:nil];
    [self setResponse:nil];
}

#pragma mark - NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    // Thanks to Nick Dowell https://gist.github.com/1885821
    if (response != nil) {
        NSMutableURLRequest *redirectableRequest =
#if WORKAROUND_MUTABLE_COPY_LEAK
        [request mutableCopyWorkaround];
#else
        [request mutableCopy];
#endif
        // We need to remove our header so we know to handle this request and cache it.
        // There are 3 requests in flight: the outside request, which we handled, the internal request,
        // which we marked with our header, and the redirectableRequest, which we're modifying here.
        // The redirectable request will cause a new outside request from the NSURLProtocolClient, which
        // must not be marked with our header.
        [redirectableRequest setValue:nil forHTTPHeaderField:RHCachingURLHeaderKey];
        
        RHCacheData *cache = [[RHCacheData alloc] init];
        [cache setResponse:response];
        [cache setData:[self data]];
        [cache setRedirectRequest:redirectableRequest];
        NSString *cachePath = [self cachePathForRequest:[self request]];
        [NSKeyedArchiver archiveRootObject:cache toFile:cachePath];
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        return redirectableRequest;
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self setResponse:response];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];  // We cache ourselves.
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
    
    RHCacheData *cache = [[RHCacheData alloc] init];
    [cache setResponse:[self response]];
    [cache setData:[self data]];
    NSString *cachePath = [self cachePathForRequest:[self request]];
    [NSKeyedArchiver archiveRootObject:cache toFile:cachePath];
    
    [self setConnection:nil];
    [self setData:nil];
    [self setResponse:nil];
}

@end
