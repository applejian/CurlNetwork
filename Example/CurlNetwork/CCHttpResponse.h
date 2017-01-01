//
//  CCHttpResponse.h
//  Example
//
//  Created by zhuruhong on 2017/1/1.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCHttpResponse : NSObject

/** the returned raw data. You can also dump it as a string */
@property (nonatomic, strong) NSMutableData *responseData;

/** the returned raw header data. You can also dump it as a string */
@property (nonatomic, strong) NSMutableData *responseHeader;

@end
