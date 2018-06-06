//
//  MTXWebViewController.m
//  Example-iOS-ObjectiveC
//
//  Created by MountainX on 2018/6/6.
//  Copyright © 2018年 MTX Software Technology Co.,Ltd. All rights reserved.
//

#import "MTXWebViewController.h"
#if MTX_WEBKIT_AVAILABLE
#import <WebKit/WebKit.h>
#else
#import "NJKWebViewProgress.h"
#import "NJKWebViewProgressView.h"
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

#if MTX_WEBKIT_AVAILABLE
API_AVAILABLE(ios(8.0))
@interface MTXWebViewController () <WKUIDelegate, WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WKWebViewConfiguration *webViewConfiguration;

/// Current web view url navigation.
@property(strong, nonatomic) WKNavigation *navigation;
#else
API_AVAILABLE(ios(7.0))
@interface MTXWebViewController () <UIWebViewDelegate>
@property (nonatomic, strong)UIWebView *webView;
@property (nonatomic, strong)NJKWebViewProgressView *progressView;
@property (nonatomic, strong)NJKWebViewProgress *progressProxy;
#endif
@property (nonatomic, strong) NSURL *URL;
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

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self setupSubviews];
    
    if (_URL) {
        [self loadURL:_URL];
    }
}

- (void)dealloc {
    [_webView stopLoading];
#if MTX_WEBKIT_AVAILABLE
    _webView.UIDelegate = nil;
    _webView.navigationDelegate = nil;
    [_webView removeObserver:self forKeyPath:KEYPATH_CONTENTOFFSET];
    [_webView removeObserver:self forKeyPath:KEYPATH_TITLE];
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

#pragma mark - UI
- (void)setupSubviews {
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    
    [self.view addSubview:self.webView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide)]];
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
    }
    return _webView;
}
#else
//- (UIWebView *)webView {
//    if (!_webView) {
//        _webView = [[UIWebView alloc] init];
//        _webView.delegate = self;
//        [self.view addSubview:_webView];
//
//        //test
//        _webView.backgroundColor = [UIColor orangeColor];
//
//        // 取消Autoresizing
//        _webView.translatesAutoresizingMaskIntoConstraints = NO;
//
//        UIEdgeInsets padding = UIEdgeInsetsMake(10, 20, 10, 20);
//        [_webView addConstraints:@[
//                                   [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:padding.top],
//                                   [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:padding.bottom],
//                                   ]];
//        // 使用Auto Layout中的VFL(Visual format language)
//        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[_webView]-right-|" options:0 metrics:@{
//                                                                                                           @"left":@(padding.left),
//                                                                                                           @"right":@(padding.right)
//                                                                                                           } views:NSDictionaryOfVariableBindings(_webView)];
//        [_webView addConstraints:constraints];
//
//    }
//    return _webView;
//}
#endif

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:KEYPATH_CONTENTOFFSET]) {
        
    } else if ([keyPath isEqualToString:KEYPATH_TITLE]) {
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
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
