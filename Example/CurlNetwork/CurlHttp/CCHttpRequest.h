//
//  CCHttpRequest.h
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCCurlRequest.h"

typedef NS_ENUM(NSInteger, CCHttpRequestType) {
    CCHttpRequestTypeGet,
    CCHttpRequestTypePost,
    CCHttpRequestTypePut,
    CCHttpRequestTypeDelete,
    CCHttpRequestTypeUnknown
};

@interface CCHttpRequest : CCCurlRequest

/** see CCHttpRequestType */
@property (nonatomic, assign) CCHttpRequestType requestType;

/** custom http headers */
@property (nonatomic, strong) NSMutableDictionary *headers;

/** used for POST */
@property (nonatomic, strong) NSMutableData *requestData;

@property (nonatomic, weak) id responseCallback;

/** You can add your customed data here */
@property (nonatomic, strong) NSMutableDictionary *userData;

@end
