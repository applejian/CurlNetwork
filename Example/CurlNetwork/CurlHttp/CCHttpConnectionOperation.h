//
//  CCHttpConnectionOperation.h
//  Example
//
//  Created by zhuruhong on 2017/1/2.
//  Copyright © 2017年 zhuruhong. All rights reserved.
//

#import "CCCurlConnectionOperation.h"

@interface CCHttpConnectionOperation : CCCurlConnectionOperation

@property (nonatomic, strong) NSString *cookieFilename;

@property (nonatomic, strong) NSString *sslCaFilename;

/**
 * An object constructed by the `responseSerializer` from the response and response data.
 * Returns `nil` unless the operation `isFinished`, has a `response`, 
 * and has `responseData` with non-zero content length. 
 * If an error occurs during serialization, `nil` will be returned, 
 * and the `error` property will be populated with the serialization error.
 */
@property (readonly, nonatomic, strong) id responseObject;

- (void)setCompletionBlockWithSuccess:(void (^)(CCHttpConnectionOperation *operation, id responseObject))success failure:(void (^)(CCHttpConnectionOperation *operation, NSError *error))failure;

@end
