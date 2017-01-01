//
//  RHCacheData.h
//  Example
//
//  Created by zhuruhong on 2016/12/31.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RHCacheData : NSObject <NSCoding>

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSURLRequest *redirectRequest;

@end
