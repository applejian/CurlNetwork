//
//  CCHttpClient.h
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCCurlConnection;

@interface CCHttpClient : NSObject

@property (nonatomic, strong, readonly) CCCurlConnection *con;


@property (nonatomic, strong) NSString *cookieFilename;

@property (nonatomic, strong) NSString *sslCaFilename;

- (void)doTest;

@end
