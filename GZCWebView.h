//
//  GZCWebView.h
//  MemberSystem
//
//  Created by GuoZhongCheng on 16/9/2.
//  Copyright © 2016年 郭忠橙. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "GZCActionSheet.h"

@class GZCWebView;
@protocol GZCWebViewDelegate <NSObject>
@optional
- (void)GZCwebView:(GZCWebView *)webview didFinishLoadingURL:(NSURL *)URL;
- (void)GZCwebView:(GZCWebView *)webview didFailToLoadURL:(NSURL *)URL error:(NSError *)error;
- (BOOL)GZCwebView:(GZCWebView *)webview shouldStartLoadWithURL:(NSURL *)URL;
- (void)GZCwebViewDidStartLoad:(GZCWebView *)webview;
- (void)GZCWebView:(GZCWebView *)webview didSavedImage:(NSString *)savedMessage;
- (void)GZCWebView:(GZCWebView *)webview didLongTapShared:(NSString *)imageUrl;
@end

@interface GZCWebView : UIView<WKNavigationDelegate, WKUIDelegate, UIWebViewDelegate,UIGestureRecognizerDelegate,GZCActionSheetDelegate>

#pragma mark - Public Properties
@property (nonatomic, weak) id <GZCWebViewDelegate> delegate;


@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) UIWebView *uiWebView;

@property (nonatomic,assign) BOOL shouldLontTapImage;  //长按图片是否显示选项,默认为no

#pragma mark - Initializers view
- (instancetype)initWithFrame:(CGRect)frame;

- (instancetype)initWithFrame:(CGRect)frame cookie:(NSArray *)cookie;

#pragma mark - Static Initializers
@property (nonatomic, strong) UIBarButtonItem *actionButton;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *barTintColor;
@property (nonatomic, assign) BOOL actionButtonHidden;
@property (nonatomic, assign) BOOL showsURLInNavigationBar;
@property (nonatomic, assign) BOOL showsPageTitleInNavigationBar;
@property (nonatomic,strong) NSDictionary * cookies;
@property (nonatomic, strong) NSArray *customActivityItems;

#pragma mark - Public Interface

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

//打开链接
- (void)loadRequest:(NSURLRequest *)request;
- (void)loadURL:(NSURL *)URL;
- (void)loadURLString:(NSString *)URLString;

//打开链接并传递cookie
- (void)loadRequest:(NSURLRequest *)request
         withCookie:(NSDictionary *)cookies;
- (void)loadURL:(NSURL *)URL
     withCookie:(NSDictionary *)cookies;
- (void)loadURLString:(NSString *)URLString
           withCookie:(NSDictionary *)cookies;

//更新cookie
-(void)updateCookie:(NSArray *)cookies url:(NSURL *)url;

//获取NSHTTPCookieStorage中的cookie，对wkwebview中可能没用
- (NSArray *)getCookies:(NSDictionary *)cookie;

//获取cookie字符串
-(void)getCookieString:(void (^)(NSString *cookieStr))completionHandle;

//清空cookie
-(void)clearCookie:(NSURL *)url;

//打开html字符串
- (void)loadHTMLString:(NSString *)HTMLString;

//清除网页缓存
+ (void)deleteWebCache;

@end
