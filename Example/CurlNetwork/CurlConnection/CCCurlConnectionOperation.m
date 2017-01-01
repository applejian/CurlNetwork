//
//  CCCurlConnectionOperation.m
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCCurlConnectionOperation.h"
#import "CCCurlRequest.h"
#import "CCCurlResponse.h"

typedef NS_ENUM(NSInteger, CCOperationState) {
    CCOperationStatePaused = -1,
    CCOperationStateReady = 1,
    CCOperationStateExecuting = 2,
    CCOperationStateFinished = 3,
};

static NSString *CCCurlConnectionDomain = @"CCCurlConnectionDomain";

static dispatch_group_t url_request_operation_completion_group() {
    static dispatch_group_t cc_url_request_operation_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cc_url_request_operation_completion_group = dispatch_group_create();
    });
    
    return cc_url_request_operation_completion_group;
}

static dispatch_queue_t url_request_operation_completion_queue() {
    static dispatch_queue_t cc_url_request_operation_completion_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cc_url_request_operation_completion_queue = dispatch_queue_create("com.curl.networking.operation.queue", DISPATCH_QUEUE_CONCURRENT );
    });
    
    return cc_url_request_operation_completion_queue;
}

static inline NSString * CCKeyPathFromOperationState(CCOperationState state) {
    switch (state) {
        case CCOperationStateReady:
            return @"isReady";
        case CCOperationStateExecuting:
            return @"isExecuting";
        case CCOperationStateFinished:
            return @"isFinished";
        case CCOperationStatePaused:
            return @"isPaused";
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            return @"state";
#pragma clang diagnostic pop
        }
    }
}

static inline BOOL CCStateTransitionIsValid(CCOperationState fromState, CCOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case CCOperationStateReady:
            switch (toState) {
                case CCOperationStatePaused:
                case CCOperationStateExecuting:
                    return YES;
                case CCOperationStateFinished:
                    return isCancelled;
                default:
                    return NO;
            }
        case CCOperationStateExecuting:
            switch (toState) {
                case CCOperationStatePaused:
                case CCOperationStateFinished:
                    return YES;
                default:
                    return NO;
            }
        case CCOperationStateFinished:
            return NO;
        case CCOperationStatePaused:
            return toState == CCOperationStateReady;
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            switch (toState) {
                case CCOperationStatePaused:
                case CCOperationStateReady:
                case CCOperationStateExecuting:
                case CCOperationStateFinished:
                    return YES;
                default:
                    return NO;
            }
        }
#pragma clang diagnostic pop
    }
}

// Callback function used by libcurl for collect header data
static size_t writeHeaderData(void *ptr, size_t size, size_t nmemb, void *stream)
{
    CCCurlConnectionOperation *con = (__bridge CCCurlConnectionOperation *)(stream);
    CCCurlResponse *response = con.response;
    size_t sizes = size * nmemb;
    
    // add data to the end of recvBuffer
    // write data maybe called more than once in a single request
    [response.responseHeader appendBytes:ptr length:sizes];
    
    NSLog(@"writeHeaderData: %zu", sizes);
    return sizes;
}

// Callback function used by libcurl for collect response data
static size_t writeData(void *ptr, size_t size, size_t nmemb, void *stream)
{
    CCCurlConnectionOperation *con = (__bridge CCCurlConnectionOperation *)(stream);
    CCCurlResponse *response = con.response;
    size_t sizes = size * nmemb;
    
    // add data to the end of recvBuffer
    // write data maybe called more than once in a single request
    [response.responseData appendBytes:ptr length:sizes];
    
    NSLog(@"writeData: %zu", sizes);
    return sizes;
}

@interface CCCurlConnectionOperation ()

@property (readwrite, nonatomic, assign) CCOperationState state;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation CCCurlConnectionOperation

+ (void)load
{
    curl_global_init(CURL_GLOBAL_ALL);
}

+ (void)networkRequestThreadEntryPoint:(id)__unused object
{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"CurlNetwork"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread
{
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (void)dealloc
{
    if (_curl) {
        curl_easy_cleanup(_curl);
        _curl = NULL;
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        _state = CCOperationStateReady;
        _runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
        _lock = [[NSRecursiveLock alloc] init];
        
        _curl = curl_easy_init();
    }
    return self;
}

- (instancetype)initWithRequest:(CCCurlRequest *)aRequest response:(CCCurlResponse *)aResponse
{
    if (self = [super init]) {
        _state = CCOperationStateReady;
        _runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
        _lock = [[NSRecursiveLock alloc] init];
        
        _curl = curl_easy_init();
        _request = aRequest;
        _response = aResponse;
    }
    return self;
}

- (void)setState:(CCOperationState)state {
    if (!CCStateTransitionIsValid(self.state, state, [self isCancelled])) {
        return;
    }
    
    [self.lock lock];
    NSString *oldStateKey = CCKeyPathFromOperationState(self.state);
    NSString *newStateKey = CCKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    [self.lock unlock];
}

- (BOOL)configureCURL
{
    CURL *handle = _curl;
    NSString *url = _request.url;
    NSTimeInterval timeoutForConnect = _request.timeoutForConnect;
    NSTimeInterval timeoutForRead = _request.timeoutForRead;
    
    if (!handle || url.length == 0) {
        return NO;
    }
    
    char *errorBuffer;
    CURLcode code;
    code = curl_easy_setopt(handle, CURLOPT_ERRORBUFFER, errorBuffer);
    if (CURLE_OK != code) {
        self.error = [self errorWithCode:code errorMsg:errorBuffer];
        return NO;
    }
    
    code = curl_easy_setopt(handle, CURLOPT_URL, [url UTF8String]);
    code = curl_easy_setopt(handle, CURLOPT_CONNECTTIMEOUT, timeoutForConnect);
    code = curl_easy_setopt(handle, CURLOPT_TIMEOUT, timeoutForRead);
    code = curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, writeData);
    code = curl_easy_setopt(handle, CURLOPT_WRITEDATA, self);
    code = curl_easy_setopt(handle, CURLOPT_HEADERFUNCTION, writeHeaderData);
    code = curl_easy_setopt(handle, CURLOPT_HEADERDATA, self);
    
    if (CURLE_OK != code) {
        self.error = [self errorWithCode:code];
        return NO;
    }
    
    return YES;
}

- (NSError *)errorWithCode:(CURLcode)aCode
{
    return [self errorWithCode:aCode errorMsg:curl_easy_strerror(aCode)];
}

- (NSError *)errorWithCode:(CURLcode)aCode errorMsg:(const char *)aErrorMsg
{
    NSString *msg = [NSString stringWithFormat:@"Curl error: %s", aErrorMsg];
    NSDictionary *userInfo = @{ @"msg": msg };
    return [NSError errorWithDomain:CCCurlConnectionDomain code:aCode userInfo:userInfo];
}

#pragma mark - NSOperation

- (void)setCompletionBlock:(void (^)(void))block {
    [self.lock lock];
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __weak __typeof(self)weakSelf = self;
        [super setCompletionBlock:^ {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_group_t group = strongSelf.completionGroup ?: url_request_operation_completion_group();
            dispatch_queue_t queue = strongSelf.completionQueue ?: dispatch_get_main_queue();
#pragma clang diagnostic pop
            
            dispatch_group_async(group, queue, ^{
                block();
            });
            
            dispatch_group_notify(group, url_request_operation_completion_queue(), ^{
                [strongSelf setCompletionBlock:nil];
            });
        }];
    }
    [self.lock unlock];
}

- (BOOL)isReady
{
    return self.state == CCOperationStateReady && [super isReady];
}

- (BOOL)isExecuting
{
    return self.state == CCOperationStateExecuting;
}

- (BOOL)isFinished
{
    return self.state == CCOperationStateFinished;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)start
{
    [self.lock lock];
    
    if ([self isCancelled]) {
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    } else if ([self isReady]) {
        self.state = CCOperationStateExecuting;
        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    
    [self.lock unlock];
}

- (void)operationDidStart
{
    [self.lock lock];
    
    if ([self isCancelled]) {
        [self.lock unlock];
        return;
    }
    
    if (![self configureCURL]) {
        [self finish];
        [self.lock unlock];
        return;
    }
    
    CURLcode code;
    code = curl_easy_perform(self.curl);
    if (CURLE_OK != code) {
        self.error = [self errorWithCode:code];
    }
    
    [self finish];
    [self.lock unlock];
}

- (void)finish
{
    [self.lock lock];
    self.state = CCOperationStateFinished;
    [self.lock unlock];
}

- (void)cancel
{
    [self.lock lock];
    
    if (![self isFinished] && ![self isCancelled]) {
        [super cancel];
        
        if ([self isExecuting]) {
            [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
        }
    }
    
    [self.lock unlock];
}

- (void)cancelConnection
{
    NSDictionary *userInfo = nil;
    if (self.request.url) {
        userInfo = @{ NSURLErrorFailingURLErrorKey: self.request.url };
    }
    self.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    
    if (![self isFinished]) {
        // Accomodate race condition where `self.connection` has not yet been set before cancellation
        [self finish];
    }
}

@end
