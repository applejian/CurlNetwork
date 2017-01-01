//
//  CCCurlRequest.h
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCCurlRequest : NSObject

/** target url that this request is sent to */
@property (nonatomic, copy) NSString *url;

/** the timeout value for connecting */
@property (nonatomic, assign) NSTimeInterval timeoutForConnect;

/** the timeout value for reading */
@property (nonatomic, assign) NSTimeInterval timeoutForRead;

@end
