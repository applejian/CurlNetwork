//
//  NSURLRequest+MutableCopyWorkaround.h
//  Example
//
//  Created by zhuruhong on 2016/12/31.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WORKAROUND_MUTABLE_COPY_LEAK 1

#if WORKAROUND_MUTABLE_COPY_LEAK
// required to workaround http://openradar.appspot.com/11596316
@interface NSURLRequest (MutableCopyWorkaround)

@end
#endif
