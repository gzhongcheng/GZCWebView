//
//  GZCWebView.h
//  GZCFrameWork
//
//  Created by GuoZhongCheng on 16/9/2.
//  Copyright © 2016年 郭忠橙. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class GZCWebView;
@protocol GZCWebViewDelegate <NSObject>
@optional

/**
 页面加载完成
 */
- (void)GZCwebView:(GZCWebView *)webview didFinishLoadingURL:(NSURL *)URL;

/**
 加载失败
 */
- (void)GZCwebView:(GZCWebView *)webview didFailToLoadURL:(NSURL *)URL error:(NSError *)error;

/**
 即将开始加载页面
 */
- (BOOL)GZCwebView:(GZCWebView *)webview shouldStartLoadWithURL:(NSURL *)URL;

/**
 开始加载
 */
- (void)GZCwebViewDidStartLoad:(GZCWebView *)webview;

/**
 长按图片事件
 */
- (void)GZCWebView:(GZCWebView *)webview longTapedImage:(NSString *)imageUrl;

@end

@interface GZCWebView : UIView<WKNavigationDelegate, WKUIDelegate>

#pragma mark - Public Properties
@property (nonatomic, weak) id <GZCWebViewDelegate> delegate;

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) WKWebView *wkWebView;

#pragma mark - Static Initializers

@property (nonatomic, strong) UIColor *tintColor;   //影响进度条颜色

@property (nonatomic,strong) NSDictionary * cookies;  //浏览器的cookie

@property (nonatomic,assign) BOOL shouldLontTapImage;  //长按图片是否显示选项,默认为no

@property (nonatomic,weak) UIViewController *controller; //弹出ActionSheet时用到的controller

#pragma mark - Initializers view
- (instancetype)initWithFrame:(CGRect)frame;

- (instancetype)initWithFrame:(CGRect)frame
                       cookie:(NSArray <NSHTTPCookie *> *)cookie
                   controller:(UIViewController *)controller;

#pragma mark - Public Interface
//设置ua
-(void)addUserAgent:(NSString *)name;

//获取当前页面的title
-(NSString *)getWebTitle;

//刷新页面
-(void)reload;

//是否可以返回（包含）上一页，这里直接调用了返回上一个页面的方法，如果需要 可自行改成只返回结果
-(BOOL)canGoBack;

//获取当前打开页面的URL
-(NSURL *)getURL;

//截图
-(void)getCapture:(void (^ )(UIImage * capture))completionHandler;

//更新cookie
-(void)updateCookie:(NSArray *)cookies url:(NSURL *)url;

//获取NSHTTPCookieStorage中的cookie，对wkwebview中可能没用
- (NSArray *)getCookies:(NSDictionary *)cookie;

//获取cookie字符串
-(void)getCookieString:(void (^)(NSString *cookieStr))completionHandle;

/**
 获取网页上的cookie ,并转换成字典格式

 @param completionHandler 回调函数
 */
-(void)getCookieDictionary:(void (^)(NSDictionary *cookieDic))completionHandler;

//清空cookie
-(void)clearCookie:(NSURL *)url;

//打开链接
- (void)loadURL:(NSURL *)URL;
- (void)loadURLString:(NSString *)URLString;
- (void)loadRequest:(NSURLRequest *)request;

//取消加载
- (void)stopLoading;

//打开链接并传递cookie
//- (void)loadURLWithCookie:(NSURL *)URL;
//- (void)loadURLStringWithCookie:(NSString *)URLString;
//- (void)loadRequestWithCookie:(NSURLRequest *)request;


//打开链接并传递cookie
- (void)loadRequest:(NSURLRequest *)request
         withCookie:(NSDictionary *)cookies;
- (void)loadURL:(NSURL *)URL
     withCookie:(NSDictionary *)cookies;
- (void)loadURLString:(NSString *)URLString
           withCookie:(NSDictionary *)cookies;

//打开html字符串
- (void)loadHTMLString:(NSString *)HTMLString;

//清除网页缓存
+ (void)deleteWebCache;

@end
