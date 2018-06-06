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

/// Time out internal.
@property(assign, nonatomic) NSTimeInterval timeoutInternal;
/// Cache policy.
@property(assign, nonatomic) NSURLRequestCachePolicy cachePolicy;
/// Shows navigation close bar button item. Default is YES.
@property(assign, nonatomic) BOOL showsNavigationCloseBarButtonItem;
/// Shows the title of navigation back bar button item. Default is YES.
@property(assign, nonatomic) BOOL showsNavigationBackBarButtonItemTitle;
/// Navigation back bar button item.
@property(strong, nonatomic) UIBarButtonItem *navigationBackBarButtonItem;
/// Navigation close bar button item.
@property(strong, nonatomic) UIBarButtonItem *navigationCloseBarButtonItem;

/**
 Get a instance of 'MTXWebViewController' by a url.

 @param url a URL to be loaded.
 @return a instance of 'MTXWebViewController'.
 */
- (instancetype)initWithURL:(NSURL *)url;

/**
 Get a instance of `MTXWebViewController` by a HTML string and a base URL.

 @param HTMLString a HTML string object.
 @param baseURL a baseURL to be loaded.
 @return a instance of `MTXWebViewController`.
 */
- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

@end
