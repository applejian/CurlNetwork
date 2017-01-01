//
//  NSString+Crypto.h
//  Example
//
//  Created by zhuruhong on 2016/12/31.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Crypto)

/**
 * Creates a SHA1 (hash) representation of NSString.
 *
 * @return NSString
 */
- (NSString *)sha1;

- (NSString *)md5;

@end
