//
//  CCHttpRequest.h
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CCHttpRequestType) {
    CCHttpRequestTypeGet,
    CCHttpRequestTypePost,
    CCHttpRequestTypePut,
    CCHttpRequestTypeDelete,
    CCHttpRequestTypeUnknown
};

@interface CCHttpRequest : NSObject

/** see CCHttpRequestType */
@property (nonatomic, assign) CCHttpRequestType requestType;

/** target url that this request is sent to */
@property (nonatomic, copy) NSString *url;

/** custom http headers */
@property (nonatomic, strong) NSMutableDictionary *headers;

/** used for POST */
@property (nonatomic, strong) NSMutableData *requestData;

@property (nonatomic, weak) id responseCallback;

/** You can add your customed data here */
@property (nonatomic, strong) NSMutableDictionary *userData;

/** the timeout value for connecting */
@property (nonatomic, assign) NSTimeInterval timeoutForConnect;

/** the timeout value for reading */
@property (nonatomic, assign) NSTimeInterval timeoutForRead;

@end
