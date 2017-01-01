//
//  RHCachingURLProtocol.h
//  Example
//
//  Created by zhuruhong on 2016/12/31.
//  Copyright © 2016年 zhuruhong. All rights reserved.
//

// RNCachingURLProtocol is a simple shim for the HTTP protocol (that’s not
// nearly as scary as it sounds). Anytime a URL is download, the response is
// cached to disk. Anytime a URL is requested, if we’re online then things
// proceed normally. If we’re offline, then we retrieve the cached version.
//
// The point of RNCachingURLProtocol is mostly to demonstrate how this is done.
// The current implementation is extremely simple. In particular, it doesn’t
// worry about cleaning up the cache. The assumption is that you’re caching just
// a few simple things, like your “Latest News” page (which was the problem I
// was solving). It caches all HTTP traffic, so without some modifications, it’s
// not appropriate for an app that has a lot of HTTP connections (see
// MKNetworkKit for that). But if you need to cache some URLs and not others,
// that is easy to implement.
//
// You should also look at [AFCache](https://github.com/artifacts/AFCache) for a
// more powerful caching engine that is currently integrating the ideas of
// RNCachingURLProtocol.
//
// A quick rundown of how to use it:
//
// 1. To build, you will need the Reachability code from Apple (included). That requires that you link with
//    `SystemConfiguration.framework`.
//
// 2. At some point early in the program (application:didFinishLaunchingWithOptions:),
//    call the following:
//
//      `[NSURLProtocol registerClass:[RNCachingURLProtocol class]];`
//
// 3. There is no step 3.
//
// For more details see
//    [Drop-in offline caching for UIWebView (and NSURLProtocol)](http://robnapier.net/blog/offline-uiwebview-nsurlprotocol-588).

#import <Foundation/Foundation.h>

@interface RHCachingURLProtocol : NSURLProtocol

@property (nonatomic, assign, getter=isUseCache) BOOL useCache;

+ (NSSet *)supportedSchemes;
+ (void)setSupportedSchemes:(NSSet *)supportedSchemes;

- (NSString *)cachePathForRequest:(NSURLRequest *)aRequest;

@end
