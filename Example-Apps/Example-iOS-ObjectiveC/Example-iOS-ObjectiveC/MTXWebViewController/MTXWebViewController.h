//
//  MTXWebViewController.h
//  Example-iOS-ObjectiveC
//
//  Created by MountainX on 2018/6/6.
//  Copyright © 2018年 MTX Software Technology Co.,Ltd. All rights reserved.
//

#ifndef __IPHONE_8_0
#define __IPHONE_8_0      80000
#endif
#ifndef __IPHONE_9_0
#define __IPHONE_9_0      90000
#endif

#ifndef MTX_WEBKIT_AVAILABLE
#define MTX_WEBKIT_AVAILABLE __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
#endif

#import <UIKit/UIKit.h>

@interface MTXWebViewController : UIViewController

/**
 Time out internal.
 */
@property(assign, nonatomic) NSTimeInterval timeoutInternal;

/**
 Cache policy.
 */
@property(assign, nonatomic) NSURLRequestCachePolicy cachePolicy;

/**
 Get a instance of 'MTXWebViewController' by a url.

 @param url a URL to be loaded.
 @return a instance of 'MTXWebViewController'.
 */
- (instancetype)initWithURL:(NSURL *)url;

@end
