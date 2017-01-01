//
//  CCCurlConnectionOperation.h
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "curl.h"

@class CCCurlRequest;
@class CCCurlResponse;

@interface CCCurlConnectionOperation : NSOperation

/**
 * The run loop modes in which the operation will run on the network thread. 
 * By default, this is a single-member set containing `NSRunLoopCommonModes`.
 */
@property (nonatomic, strong) NSSet *runLoopModes;

/** 
 * The dispatch queue for `completionBlock`. 
 * If `NULL` (default), the main queue is used. 
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

/** 
 * The dispatch group for `completionBlock`. 
 * If `NULL` (default), a private dispatch group is used. 
 */
@property (nonatomic, strong) dispatch_group_t completionGroup;


/** Instance of CURL */
@property (nonatomic, assign, readonly) CURL *curl;

/** The request used by the operation's connection */
@property (nonatomic, strong) CCCurlRequest *request;

/** The last response received by the operation's connection */
@property (nonatomic, strong) CCCurlResponse *response;

/** The error, if any, that occurred in the lifecycle of the request */
@property (nonatomic, strong) NSError *error;

- (instancetype)initWithRequest:(CCCurlRequest *)aRequest response:(CCCurlResponse *)aResponse;

- (BOOL)configureCURL;

- (NSError *)errorWithCode:(CURLcode)aCode;
- (NSError *)errorWithCode:(CURLcode)aCode errorMsg:(const char *)aErrorMsg;

@end
