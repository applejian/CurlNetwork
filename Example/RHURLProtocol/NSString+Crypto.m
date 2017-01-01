//
//  NSString+Crypto.m
//  Example
//
//  Created by zhuruhong on 2016/12/31.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import "NSString+Crypto.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Crypto)

- (NSString *)sha1
{
    // see http://www.makebetterthings.com/iphone/how-to-get-md5-and-sha1-in-objective-c-ios-sdk/
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

- (NSString *)md5
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[16];
    
    CC_MD5(data.bytes, (CC_LONG)data.length, digest); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

@end
