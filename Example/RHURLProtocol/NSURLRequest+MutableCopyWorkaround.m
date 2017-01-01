//
//  NSURLRequest+MutableCopyWorkaround.m
//  Example
//
//  Created by zhuruhong on 2016/12/31.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import "NSURLRequest+MutableCopyWorkaround.h"

#if WORKAROUND_MUTABLE_COPY_LEAK
@implementation NSURLRequest (MutableCopyWorkaround)

- (id) mutableCopyWorkaround {
    NSMutableURLRequest *mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:[self URL]
                                                                          cachePolicy:[self cachePolicy]
                                                                      timeoutInterval:[self timeoutInterval]];
    [mutableURLRequest setAllHTTPHeaderFields:[self allHTTPHeaderFields]];
    if ([self HTTPBodyStream]) {
        [mutableURLRequest setHTTPBodyStream:[self HTTPBodyStream]];
    } else {
        [mutableURLRequest setHTTPBody:[self HTTPBody]];
    }
    [mutableURLRequest setHTTPMethod:[self HTTPMethod]];
    
    return mutableURLRequest;
}

@end
#endif
