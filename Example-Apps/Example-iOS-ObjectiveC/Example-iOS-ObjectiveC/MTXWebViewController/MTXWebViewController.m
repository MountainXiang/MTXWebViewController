//
//  MTXWebViewController.m
//  Example-iOS-ObjectiveC
//
//  Created by MountainX on 2018/6/6.
//  Copyright © 2018年 MTX Software Technology Co.,Ltd. All rights reserved.
//

#import "MTXWebViewController.h"
#import "NJKWebViewProgress.h"
#import "NJKWebViewProgressView.h"
#import "WebViewJavascriptBridge.h"
#if MTX_WEBKIT_AVAILABLE
#import <WebKit/WebKit.h>
#else

#endif

#ifndef MTXWebViewControllerLocalizedString
#define MTXWebViewControllerLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, @"MTXWebViewController", self.resourceBundle, comment)
#endif

/**
 定义日志宏*/
#ifdef DEBUG
/*
 __PRETTY_FUNCTION__  非标准宏。这个宏比__FUNCTION__功能更强,  若用g++编译C++程序, __FUNCTION__只能输出类的成员名,不会输出类名;而__PRETTY_FUNCTION__则会以 <return-type>  <class-name>::<member-function-name>(<parameters-list>) 的格式输出成员函数的详悉信息(注: 只会输出parameters-list的形参类型, 而不会输出形参名).若用gcc编译C程序,__PRETTY_FUNCTION__跟__FUNCTION__的功能相同.
 
 __LINE__ 宏在预编译时会替换成当前的行号
 
 __VA_ARGS__ 是一个可变参数的宏，很少人知道这个宏，这个可变参数的宏是新的C99规范中新增的，目前似乎只有gcc支持（VC6.0的编译器不支持）。宏前面加上##的作用在于，当可变参数的个数为0时，这里的##起到把前面多余的","去掉的作用,否则会编译出错
 */
//#define MTXLOG(...) NSLog(__VA_ARGS__);
#define MTXLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#define MTXLOG_METHOD NSLog(@"%s",__func__);
#define MTXLOG_ERROR(fmt,...) NSLog((@"Error:%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#define MTXLOG_WARNING(fmt,...) NSLog((@"Warning:%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define MTXLOG(...) ;
#define MTXLOG_METHOD ;
#define MTXLOG_ERROR(fmt,...) ;
#define MTXLOG_WARNING(fmt,...) ;
#endif

static NSString *KEYPATH_CONTENTOFFSET = @"scrollView.contentOffset";
static NSString *KEYPATH_TITLE = @"title";
static NSString *KEYPATH_ESTIMATEDPROGRESS  = @"estimatedProgress";

#if MTX_WEBKIT_AVAILABLE
API_AVAILABLE(ios(8.0))
@interface MTXWebViewController () <WKUIDelegate, WKNavigationDelegate>
{
    UIBarButtonItem * __weak _doneItem;
}
@property (nonatomic, strong) WKWebView                  *webView;
@property (nonatomic, strong) WKWebViewConfiguration     *webViewConfiguration;
/// Current web view url navigation.
@property (strong, nonatomic) WKNavigation               *navigation;
#else
API_AVAILABLE(ios(7.0))
@interface MTXWebViewController () <UIWebViewDelegate, NJKWebViewProgressDelegate>
{
    UIBarButtonItem * __weak _doneItem;
}
@property (nonatomic, strong) UIWebView                  *webView;
#endif
@property (nonatomic, strong) NSURL                      *URL;
@property (nonatomic, copy) NSString                     *HTMLString;
@property (nonatomic, strong) NSURL                      *baseURL;

@property (nonatomic, strong) NJKWebViewProgressView     *progressView;
@property (nonatomic, strong) NJKWebViewProgress         *progressProxy;
@property (nonatomic, strong) NSBundle                   *resourceBundle;
/**
 Max length of title string content. Default: UIDeviceOrientationPortrait -> 20 ; UIDeviceOrientationLandscape -> 40;
 */
@property(assign, nonatomic) NSUInteger maxAllowedTitleLength;
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;



@end

@implementation MTXWebViewController

#pragma mark - Life Cycle
#pragma mark Init
- (instancetype)init {
    if (self = [super init]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight) {
        _maxAllowedTitleLength = 40;
    } else {
        _maxAllowedTitleLength = 20;
    }
    
    _showsNavigationCloseBarButtonItem = YES;
    _showsNavigationBackBarButtonItemTitle = YES;
    
    // Set up default values.
    if (@available(iOS 8.0, *)) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = NO;
    } else {
        
    }
}

#pragma mark - Convenient Initialization
- (instancetype)initWithURL:(NSURL *)url {
    if (self = [self init]) {
        _URL = url;
    }
    return self;
}

- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    if (self = [self init]) {
        _HTMLString = HTMLString;
        _baseURL = baseURL;
    }
    return self;
}

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Do any additional setup after loading the view.
    [self setupSubviews];
    
    if (_URL) {
        [self loadURL:_URL];
    } else if (_HTMLString) {
        [self loadHTMLString:_HTMLString baseURL:_baseURL];
        
        //test
#ifdef DEBUG
        [WebViewJavascriptBridge enableLogging];
#endif
        
        _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView];
        [_bridge setWebViewDelegate:self];
        
        [_bridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
            NSLog(@"testObjcCallback called: %@", data);
            responseCallback(@"Response from testObjcCallback");
        }];
        
        [_bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready" }];
        
        [self renderButtons:_webView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Add progress view to navigation bar.
    if (self.navigationController && self.progressView.superview != self.navigationController.navigationBar) {
        [self _updateFrameOfProgressView];
        [self.navigationController.navigationBar addSubview:self.progressView];
    }
    if (self.navigationController && [self.navigationController isBeingPresented]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonClicked:)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.navigationItem.leftBarButtonItem = doneButton;
        else
            self.navigationItem.rightBarButtonItem = doneButton;
        _doneItem = doneButton;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //----- SETUP DEVICE ORIENTATION CHANGE NOTIFICATION -----
    UIDevice *device = [UIDevice currentDevice]; //Get the device object
    [device beginGeneratingDeviceOrientationNotifications]; //Tell it to start monitoring the accelerometer for orientation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.progressView.superview) {
        [self.progressView removeFromSuperview];
    }
}

- (void)dealloc {
    [_webView stopLoading];
#if MTX_WEBKIT_AVAILABLE
    _webView.UIDelegate = nil;
    _webView.navigationDelegate = nil;
    [_webView removeObserver:self forKeyPath:KEYPATH_CONTENTOFFSET];
    [_webView removeObserver:self forKeyPath:KEYPATH_TITLE];
    [_webView removeObserver:self forKeyPath:KEYPATH_ESTIMATEDPROGRESS];
#else
    _webView.delegate = nil;
    // Load empty request to fix UIWebView's memory leak bug.
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
#endif
    MTXLOG(@"One of MTXWebViewController's instances was destroyed.");
}

#pragma mark - Public
- (void)loadURL:(NSURL *)pageURL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pageURL];
    request.timeoutInterval = _timeoutInternal;
    request.cachePolicy = _cachePolicy;
#if MTX_WEBKIT_AVAILABLE
    _navigation = [_webView loadRequest:request];
#else
    [_webView loadRequest:request];
#endif
}

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    _baseURL = baseURL;
    _HTMLString = HTMLString;
#if MTX_WEBKIT_AVAILABLE
    _navigation = [_webView loadHTMLString:HTMLString baseURL:baseURL];
#else
    [_webView loadHTMLString:HTMLString baseURL:baseURL];
#endif
}

- (void)didFinishLoad{
    [self updateNavigationItems];
}

#pragma mark - Actions
- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender {
#if AX_WEB_VIEW_CONTROLLER_USING_WEBKIT
    if ([_webView canGoBack]) {
        _navigation = [_webView goBack];
        return;
    }
#else
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        return;
    }
#endif
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationIemHandleClose:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI
- (void)setupSubviews {
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    
    [self.view addSubview:self.webView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide)]];
}

- (void)renderButtons:(UIView *)webView {
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setTitle:@"Call handler" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(10, 400, 100, 35);
    callbackButton.titleLabel.font = font;
    
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"Reload webview" forState:UIControlStateNormal];
    [reloadButton addTarget:webView action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.frame = CGRectMake(110, 400, 100, 35);
    reloadButton.titleLabel.font = font;
}

#pragma mark - WebViewJavascriptBridge Call Handler
- (void)callHandler:(id)sender {
    id data = @{ @"greetingFromObjC": @"Hi there, JS!" };
    [_bridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
        NSLog(@"testJavascriptHandler responded: %@", response);
    }];
}

#pragma mark - Setters
- (void)setMaxAllowedTitleLength:(NSUInteger)maxAllowedTitleLength {
    _maxAllowedTitleLength = maxAllowedTitleLength;
    [self _updateTitleOfWebVC];
}

#pragma mark - Getters
#if MTX_WEBKIT_AVAILABLE
- (WKWebViewConfiguration *)webViewConfiguration API_AVAILABLE(ios(8.0)){
    if (!_webViewConfiguration) {
        _webViewConfiguration = [[WKWebViewConfiguration alloc] init];
        _webViewConfiguration.preferences.minimumFontSize = 9.0;
        if ([_webViewConfiguration respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
            [_webViewConfiguration setAllowsInlineMediaPlayback:YES];
        }
        
        if (@available(iOS 9.0, *)) {
            if ([_webViewConfiguration respondsToSelector:@selector(setApplicationNameForUserAgent:)]) {
                [_webViewConfiguration setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
            }
        } else {
            // Fallback on earlier versions
        }
        
        if (@available(iOS 10.0, *)) {
            if ([_webViewConfiguration respondsToSelector:@selector(setMediaTypesRequiringUserActionForPlayback:)]){
                [_webViewConfiguration setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];
            }
        } else if (@available(iOS 9.0, *)) {
            if ( [_webViewConfiguration respondsToSelector:@selector(setRequiresUserActionForMediaPlayback:)]) {
                [_webViewConfiguration setRequiresUserActionForMediaPlayback:NO];
            }
        } else {
            if ( [_webViewConfiguration respondsToSelector:@selector(setMediaPlaybackRequiresUserAction:)]) {
                [_webViewConfiguration setMediaPlaybackRequiresUserAction:NO];
            }
        }
    }
    return _webViewConfiguration;
}

-(WKWebView *)webView API_AVAILABLE(ios(8.0)){
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:self.webViewConfiguration];
        _webView.allowsBackForwardNavigationGestures = YES;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.scrollView.backgroundColor = [UIColor clearColor];
        // Set auto layout enabled.
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        // Set Delegate
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        // Observe the content offset of the scroll view.
        [_webView addObserver:self forKeyPath:KEYPATH_CONTENTOFFSET options:NSKeyValueObservingOptionNew context:NULL];
        // Observe title.
        [_webView addObserver:self forKeyPath:KEYPATH_TITLE options:NSKeyValueObservingOptionNew context:NULL];
        // Observe estimated progress.
        [_webView addObserver:self forKeyPath:KEYPATH_ESTIMATEDPROGRESS options:NSKeyValueObservingOptionNew context:NULL];
    }
    return _webView;
}
#else
- (UIWebView *)webView {
    if (!_webView) {
        _webView = [[UIWebView alloc] init];
        // Set auto layout enabled.
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _webView;
}

- (NJKWebViewProgress *)progressProxy {
    if (!_progressProxy) {
        _progressProxy = [[NJKWebViewProgress alloc] init];
        _webView.delegate = _progressProxy;
        _progressProxy.webViewProxyDelegate = self;
        _progressProxy.progressDelegate = self;
    }
    return _progressProxy;
}
#endif

- (NJKWebViewProgressView *)progressView {
    if (!_progressView) {
        CGFloat progressBarHeight = 2.f;
        CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
        CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
        _progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    return _progressView;
}

- (NSBundle *)resourceBundle {
    if (!_resourceBundle) {
        _resourceBundle = [NSBundle bundleForClass:[self class]];
//        NSString *resourcePath = [_resourceBundle pathForResource:@"AXWebViewController" ofType:@"bundle"] ;
//        if (resourcePath){
//            NSBundle *bundle = [NSBundle bundleWithPath:resourcePath];
//            if (bundle){
//                _resourceBundle = bundle;
//            }
//        }
    }
    return _resourceBundle;
}

- (UIBarButtonItem *)navigationBackBarButtonItem {
    if (_navigationBackBarButtonItem) return _navigationBackBarButtonItem;
    UIImage* backItemImage = [[[UINavigationBar appearance] backIndicatorImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]?:[[UIImage imageNamed:@"backItemImage" inBundle:self.resourceBundle compatibleWithTraitCollection:nil]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(backItemImage.size, NO, backItemImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, backItemImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, backItemImage.size.width, backItemImage.size.height);
    CGContextClipToMask(context, rect, backItemImage.CGImage);
    [[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] setFill];
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage* backItemHlImage = newImage?:[[UIImage imageNamed:@"backItemImage-hl" inBundle:self.resourceBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    NSDictionary *attr = [[UIBarButtonItem appearance] titleTextAttributesForState:UIControlStateNormal];
    NSString *backBarButtonItemTitleString = self.showsNavigationBackBarButtonItemTitle ? MTXWebViewControllerLocalizedString(@"back", @"back") : @"    ";
    if (attr) {
        [backButton setAttributedTitle:[[NSAttributedString alloc] initWithString:backBarButtonItemTitleString attributes:attr] forState:UIControlStateNormal];
        UIOffset offset = [[UIBarButtonItem appearance] backButtonTitlePositionAdjustmentForBarMetrics:UIBarMetricsDefault];
        backButton.titleEdgeInsets = UIEdgeInsetsMake(offset.vertical, offset.horizontal, 0, 0);
        backButton.imageEdgeInsets = UIEdgeInsetsMake(offset.vertical, offset.horizontal, 0, 0);
    } else {
        [backButton setTitle:backBarButtonItemTitleString forState:UIControlStateNormal];
        [backButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    }
    [backButton setImage:backItemImage forState:UIControlStateNormal];
    [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
    [backButton sizeToFit];
    
    [backButton addTarget:self action:@selector(navigationItemHandleBack:) forControlEvents:UIControlEventTouchUpInside];
    _navigationBackBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    return _navigationBackBarButtonItem;
}

- (UIBarButtonItem *)navigationCloseBarButtonItem {
    if (_navigationCloseBarButtonItem) return _navigationCloseBarButtonItem;
    if (self.navigationItem.rightBarButtonItem == _doneItem && self.navigationItem.rightBarButtonItem != nil) {
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:MTXWebViewControllerLocalizedString(@"close", @"close") style:0 target:self action:@selector(doneButtonClicked:)];
    } else {
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:MTXWebViewControllerLocalizedString(@"close", @"close") style:0 target:self action:@selector(navigationIemHandleClose:)];
    }
    return _navigationCloseBarButtonItem;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:KEYPATH_CONTENTOFFSET]) {
        // Get the current content offset.
//        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
    } else if ([keyPath isEqualToString:KEYPATH_TITLE]) {
        [self _updateTitleOfWebVC];
    } else if ([keyPath isEqualToString:KEYPATH_ESTIMATEDPROGRESS]) {
        // Add progress view to navigation bar.
        if (self.navigationController && self.progressView.superview != self.navigationController.navigationBar) {
            [self _updateFrameOfProgressView];
            [self.navigationController.navigationBar addSubview:self.progressView];
        }
        float progress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        if (progress >= _progressView.progress) {
            [_progressView setProgress:progress animated:YES];
        } else {
            [_progressView setProgress:progress animated:NO];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - HandleDeviceOrientationChangedNoti
- (void)orientationChanged:(NSNotification *)noti {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight) {
        self.maxAllowedTitleLength = 40;
    } else {
        self.maxAllowedTitleLength = 20;
    }
    switch (deviceOrientation) {
        case UIDeviceOrientationFaceUp:
            MTXLOG(@"屏幕朝上平躺");
            break;
            
        case UIDeviceOrientationFaceDown:
            MTXLOG(@"屏幕朝下平躺");
            break;
            
        case UIDeviceOrientationUnknown:
            MTXLOG(@"未知方向");
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            MTXLOG(@"屏幕向左横置");
            break;
            
        case UIDeviceOrientationLandscapeRight:
            MTXLOG(@"屏幕向右橫置");
            break;
            
        case UIDeviceOrientationPortrait:
            MTXLOG(@"屏幕直立");
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            MTXLOG(@"屏幕直立，上下顛倒");
            break;
            
        default:
            MTXLOG(@"无法辨识");
            break;
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self didFinishLoad];
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self updateNavigationItems];
}

#pragma mark - NJKWebViewProgressDelegate
-(void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    // Add progress view to navigation bar.
    if (self.navigationController && self.progressView.superview != self.navigationController.navigationBar) {
        [self _updateFrameOfProgressView];
        [self.navigationController.navigationBar addSubview:self.progressView];
    }
    [self.progressView setProgress:progress animated:YES];
}

#pragma mark - Helper
- (void)_updateFrameOfProgressView {
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView.frame = barFrame;
}

- (void)_updateTitleOfWebVC {
    NSString *title = self.title;
#if MTX_WEBKIT_AVAILABLE
    title = title.length > 0 ? title: [_webView title];
#else
    title = title.length > 0 ? title: [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
#endif
    title = [self shortText:title];
    self.navigationItem.title = title.length > 0 ? title : MTXWebViewControllerLocalizedString(@"browsing the web", @"browsing the web");
}

/*编码不同，占的字节不同。
 ASCII码：一个英文字母（不分大小写）占一个字节的空间，一个中文汉字占两个字节的空间。
 UTF-8编码：一个英文字符等于一个字节，一个中文（含繁体）等于三个字节。中文标点占三个字节，英文标点占一个字节
 Unicode编码：一个英文等于两个字节，一个中文（含繁体）等于两个字节。中文标点占两个字节，英文标点占两个字节
 字节是指一小组相邻的二进制数码。通常是8位作为一个字节。它是构成信息的一个小单位，并作为一个整体来参加操作，比字小，是构成字的单位。
 在微型计算机中，通常用多少字节来表示存储器的存储容量。
 例如，在C++的数据类型表示中，通常char为1个字节，int为4个字节，double为8个字节。*/
- (NSString *)shortText:(NSString *)text {
    NSUInteger textBytes = 0;
    NSUInteger index = 0;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar uc = [text characterAtIndex: i];
        //isascii是C语言中的字符检测函数。通常用于检查参数c是否为ASCII 码字符，也就是判断c 的范围是否在0 到127 之间。
        textBytes += isascii(uc) ? 1 : 2;
        if (textBytes > _maxAllowedTitleLength) {
            index = i;
            break;
        }
    }
    if (index > 0) {
        text = [[text substringToIndex:index] stringByAppendingString:@"..."];
    }
    return text;
}

- (void)updateNavigationItems {
    [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    if (self.webView.canGoBack/* || self.webView.backForwardList.backItem*/) {// Web view can go back means a lot requests exist.
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        if (self.navigationController.viewControllers.count == 1) {
            NSMutableArray *leftBarButtonItems = [NSMutableArray arrayWithArray:@[spaceButtonItem,self.navigationBackBarButtonItem]];
            // If the top view controller of the navigation controller is current vc, the close item is ignored.
            if (self.showsNavigationCloseBarButtonItem && self.navigationController.topViewController != self){
                [leftBarButtonItems addObject:self.navigationCloseBarButtonItem];
            }
            
            [self.navigationItem setLeftBarButtonItems:leftBarButtonItems animated:NO];
        } else {
            if (self.showsNavigationCloseBarButtonItem){
                [self.navigationItem setLeftBarButtonItems:@[self.navigationBackBarButtonItem, self.navigationCloseBarButtonItem] animated:NO];
            }else{
                [self.navigationItem setLeftBarButtonItems:@[self.navigationBackBarButtonItem] animated:NO];
            }
        }
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
