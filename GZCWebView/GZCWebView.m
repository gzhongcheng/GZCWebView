//
//  GZCWebView.m
//  GZCFrameWork
//
//  Created by GuoZhongCheng on 16/9/2.
//  Copyright © 2016年 郭忠橙. All rights reserved.
//

#import "GZCWebView.h"
#import "WKWebView+ScreenCapture.h"
#import "SDAutoLayout.h"

#define progressTintColor [UIColor colorWithRed:0.400 green:0.863 blue:0.133 alpha:1.000]
static void *GZCWebBrowserContext = &GZCWebBrowserContext;

@interface GZCWebView ()<UIAlertViewDelegate,UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSURL *URLToLaunchWithPermission;
@property (nonatomic, strong) UIAlertView *externalAppPermissionAlertView;
/**
 WKWebview的cookie
 */
@property (nonatomic,strong) NSArray *wkCookies;

@end

@implementation GZCWebView

#pragma mark --Initializers
-(instancetype)initWithFrame:(CGRect)frame{
    return [self initWithFrame:frame cookie:nil controller:nil];
}

- (instancetype)initWithFrame:(CGRect)frame cookie:(NSArray <NSHTTPCookie *> *)cookie controller:(UIViewController *)controller
{
    self = [super initWithFrame:frame];
    if (self) {
        self.controller = controller;
        if ([cookie count]) {
            self.wkWebView = [[WKWebView alloc]initWithFrame:self.bounds configuration:[self getconfigurationWithCookies:cookie]];
        }else{
            self.wkWebView = [[WKWebView alloc] init];
        }
        self.wkWebView.sd_layout.spaceToSuperView(UIEdgeInsetsMake(0, 0, 0, 0));
        [self.wkWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.wkWebView setNavigationDelegate:self];
        [self.wkWebView setUIDelegate:self];
        [self.wkWebView setMultipleTouchEnabled:YES];
        [self.wkWebView setAutoresizesSubviews:YES];
        [self.wkWebView.scrollView setAlwaysBounceVertical:YES];
        self.wkWebView.allowsBackForwardNavigationGestures =YES;
        [self addSubview:self.wkWebView];
        self.wkWebView.scrollView.bounces = NO;
        [self.wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:GZCWebBrowserContext];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(wkLongPressed:)];
        longPress.delegate = self;
        [self.wkWebView addGestureRecognizer:longPress];
        
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self.progressView setTrackTintColor:[UIColor colorWithWhite:1.0f alpha:0.0f]];
        [self.progressView setFrame:CGRectMake(0, 0, self.frame.size.width,3)];
        
        //设置进度条颜色
        [self setTintColor:progressTintColor];
        [self addSubview:self.progressView];
        
    }
    return self;
}



#pragma mark - Public Interface
-(void)updateCookie:(NSArray *)cookies url:(NSURL *)url{
    // 设置header，通过遍历cookies来一个一个的设置header
    for (NSHTTPCookie *cookie in cookies){
        // cookiesWithResponseHeaderFields方法，需要为URL设置一个cookie为NSDictionary类型的header，注意NSDictionary里面的forKey需要是@"Set-Cookie"
        NSArray *headeringCookie = [NSHTTPCookie cookiesWithResponseHeaderFields:
                                    [NSDictionary dictionaryWithObject:
                                     [[NSString alloc] initWithFormat:@"%@=%@",[cookie name],[cookie value]]
                                                                forKey:@"Set-Cookie"]
                                                                          forURL:url];
        // 通过setCookies方法，完成设置，这样只要一访问URL为HOST的网页时，会自动附带上设置好的header
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:headeringCookie
                                                           forURL:url
                                                  mainDocumentURL:nil];
    }
    if ([cookies count]) {
        NSDictionary *headers=[NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        WKUserContentController* userContentController = self.wkWebView.configuration.userContentController;
        WKUserScript * cookieScript = [[WKUserScript alloc]
                                       initWithSource:[NSString stringWithFormat:@"document.cookie ='%@';",[headers objectForKey:@"Cookie"]]
                                       injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                       forMainFrameOnly:NO];
        [userContentController addUserScript:cookieScript];
    }else{
        [self.wkWebView.configuration.userContentController removeAllUserScripts];
//            [self deleteWebCache];
    }
}

+ (void)deleteWebCache {
    if (@available(iOS 9.0, *)) {
        // 所有缓存
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        // 设置日期
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        // 执行
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            // 完成
        }];
        
    } else {
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
        NSError *errors;
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
        
    }
}

-(void)addUserAgent:(NSString *)name{
    [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
        NSString *userAgent = result;
        NSString *newUserAgent = [userAgent stringByAppendingString:name];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newUserAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
        }];
    }];
}

-(NSString *)getWebTitle{
    return self.wkWebView.title;
}

-(void)reload{
    [self.wkWebView reload];
}

-(BOOL)canGoBack{
    if (self.wkWebView.canGoBack) {
        [self.wkWebView goBack];
        return YES;
    }else {
        return NO;
    }
}

-(NSURL *)getURL{
    return self.wkWebView.URL;;
}

-(void)getCapture:(void (^)(UIImage *))completionHandler{
    [self.wkWebView captureCallback:^(UIImage *image) {
        completionHandler(image);
    }];
}

-(void)clearCookie:(NSURL *)url{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookieAry = [cookieJar cookies];
    for (cookie in cookieAry) {
        [cookieJar deleteCookie: cookie];
    }
    [self updateCookie:nil url:url];
}

-(void)getCookieString:(void (^)(NSString *))completionHandle{
    [self.wkWebView evaluateJavaScript:@"document.cookie" completionHandler:^(id _Nullable message, NSError * _Nullable error) {
        completionHandle(message);
    }];
}

#pragma mark - loadUrl
-(void)loadURL:(NSURL *)URL withCookie:(NSDictionary *)cookies{
    [self loadRequest:[NSURLRequest requestWithURL:URL] withCookie:cookies];
}

-(void)loadURLString:(NSString *)URLString withCookie:(NSDictionary *)cookies{
    NSURL *URL = [NSURL URLWithString:URLString];
    [self loadURL:URL withCookie:cookies];
}

-(void)loadRequest:(NSURLRequest *)request withCookie:(NSDictionary *)cookies{
    if (self.cookies != cookies) {
        self.cookies = cookies;
    }
    NSMutableURLRequest *mrequest = [NSMutableURLRequest requestWithURL:request.URL];
    
    if (cookies == nil) {
        [self.wkWebView loadRequest:mrequest];
        return;
    }
    //获取原来的cookie
    [self getCookieString:^(NSString *cookieStr) {
        for (NSString *key in [cookies allKeys]) {
            //如果没有cookies中的值存在，就拼接上去
            if (cookieStr == nil) {
                cookieStr = [NSString stringWithFormat:@"%@=%@",key,[cookies objectForKey:key]];
            }else
                if ([cookieStr rangeOfString:key].length == 0) {
                    cookieStr = [NSString stringWithFormat:@"%@;%@=%@",cookieStr,key,[cookies objectForKey:key]];
                }
        }
        //设置cookie到header
        [mrequest addValue:cookieStr forHTTPHeaderField:@"Cookie"];
        //打开请求
        [self.wkWebView loadRequest:mrequest];
    }];
}

- (void)loadURL:(NSURL *)URL {
    [self loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)loadURLString:(NSString *)URLString {
    NSURL *URL = [NSURL URLWithString:URLString];
    [self loadURL:URL];
}

- (void)loadRequest:(NSURLRequest *)request {
    [self.wkWebView loadRequest:request];
}

- (void)loadHTMLString:(NSString *)HTMLString {
    [self.wkWebView loadHTMLString:HTMLString baseURL:nil];
}

- (void)stopLoading{
    [self.wkWebView stopLoading];
}

#pragma mark - set

- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self.progressView setTintColor:tintColor];
}

#pragma mark - cookie get
- (WKWebViewConfiguration *)getconfigurationWithCookies:(NSArray *)cookies{
    if ([cookies count]) {
        //写入cookie
        NSDictionary *headers=[NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        WKUserContentController* userContentController = WKUserContentController.new;
        WKUserScript * cookieScript = [[WKUserScript alloc]
                                       initWithSource:[NSString stringWithFormat:@"document.cookie ='%@';",[headers objectForKey:@"Cookie"]]
                                       injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                       forMainFrameOnly:NO];
        [userContentController addUserScript:cookieScript];
        
        WKWebViewConfiguration* webViewConfig = WKWebViewConfiguration.new;
        webViewConfig.userContentController = userContentController;
        return webViewConfig;
    }
    return nil;
}

-(void)getCookieDictionary:(void (^)(NSDictionary *cookieDic))completionHandler{
    [self getCookieString:^(NSString *cookieStr) {
        if ([cookieStr isKindOfClass:[NSString class]]) {
            NSArray * array = [cookieStr componentsSeparatedByString:@";"];
            NSMutableDictionary *cookies = [NSMutableDictionary dictionary];
            for (NSString * str in array) {
                NSArray *kv = [str componentsSeparatedByString:@"="];
                if ([kv count]==2) {
                    NSString *key = [kv[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSString *value = kv[1];
                    [cookies setValue:value forKey:key];
                }
            }
            completionHandler(cookies);
        }else{
            completionHandler(nil);
        }
    }];
}

- (NSArray *)getCookies:(NSDictionary *)cookie{
    NSMutableArray *cookies = [NSMutableArray array];
    for (NSString *key in [cookie allKeys]) {
        NSDictionary *properties = [[NSMutableDictionary alloc] init];
        [properties setValue:[cookie objectForKey:key] forKey:NSHTTPCookieValue];
        [properties setValue:key forKey:NSHTTPCookieName];
        [properties setValue:@"" forKey:NSHTTPCookieDomain];
        [properties setValue:[NSDate dateWithTimeIntervalSinceNow:60*60] forKey:NSHTTPCookieExpires];
        [properties setValue:@"/" forKey:NSHTTPCookiePath];
        NSHTTPCookie *cookie = [[NSHTTPCookie alloc] initWithProperties:properties];
        [cookies addObject:cookie];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }
    return cookies;
}

#pragma mark - target

- (void)wkLongPressed:(UILongPressGestureRecognizer*)sender
{
    if (!self.shouldLontTapImage||sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    CGPoint touchPoint = [sender locationInView:self.wkWebView];
    // 获取长按位置对应的图片url的JS代码
    NSString *imgJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
    // 执行对应的JS代码 获取url
    [self.wkWebView evaluateJavaScript:imgJS completionHandler:^(id _Nullable imgUrl, NSError * _Nullable error) {
        [self longTapImageWithUrl:imgUrl];
    }];
}

-(void)longTapImageWithUrl:(NSString *)imgUrl{
    if (imgUrl) {
        if ([self.delegate respondsToSelector:@selector(GZCWebView:longTapedImage:)]) {
            [self.delegate GZCWebView:self longTapedImage:imgUrl];
        }
    }
}



#pragma mark - WKNavigationDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if(webView == self.wkWebView&&[self.delegate respondsToSelector:@selector(GZCwebViewDidStartLoad:)]) {
        //back delegate
        [self.delegate GZCwebViewDidStartLoad:self];
        //        WKNavigationActionPolicy(WKNavigationActionPolicyAllow);
        
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    if(webView == self.wkWebView && [self.delegate respondsToSelector:@selector(GZCwebView:didFinishLoadingURL:)]) {
        
        //back delegate
        [self.delegate GZCwebView:self didFinishLoadingURL:self.wkWebView.URL];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView && [self.delegate respondsToSelector:@selector(GZCwebView:didFailToLoadURL:error:)]) {
        //back delegate
        [self.delegate GZCwebView:self didFailToLoadURL:self.wkWebView.URL error:error];
    }
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView && [self.delegate respondsToSelector:@selector(GZCwebView:didFailToLoadURL:error:)]) {
        //back delegate
        [self.delegate GZCwebView:self didFailToLoadURL:self.wkWebView.URL error:error];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
//    NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
//    NSArray *cookies =[NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
    //读取wkwebview中的cookie 方法1
//    for (NSHTTPCookie *cookie in cookies) {
        //        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
//        NSLog(@"wkwebview中的cookie:%@", cookie);
        
//    }
    //读取wkwebview中的cookie 方法2 读取Set-Cookie字段
//    NSString *cookieString = [[response allHeaderFields] valueForKey:@"Set-Cookie"];
//    NSLog(@"wkwebview中的cookie:%@", cookieString);
    
    //看看存入到了NSHTTPCookieStorage了没有
//    NSHTTPCookieStorage *cookieJar2 = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    for (NSHTTPCookie *cookie in cookieJar2.cookies) {
//        NSLog(@"NSHTTPCookieStorage中的cookie%@", cookie);
//    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    if(webView == self.wkWebView) {
        
        NSURL *URL = navigationAction.request.URL;
        if(![self externalAppRequiredToOpenURL:URL]) {
            if(!navigationAction.targetFrame) {
//                [self loadURLWithCookie:URL];
                [self loadRequest:navigationAction.request withCookie:self.cookies];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            NSString *path= URL.absoluteString;
            if ([path hasPrefix:@"sms:"] || [path hasPrefix:@"tel:"]) {
                UIApplication * app = [UIApplication sharedApplication];
                if ([app canOpenURL:[NSURL URLWithString:path]]) {
                    [app openURL:[NSURL URLWithString:path]];
                }
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            if(![self callback_webViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType]){
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        else if([[UIApplication sharedApplication] canOpenURL:URL]) {
            [self launchExternalAppWithURL:URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    // js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler();
                                                      }]];
    if(self.controller)
        [self.controller presentViewController:alertController animated:YES completion:^{}];
    
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    //  js 里面的alert实现，如果不实现，网页的alert函数无效  ,
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(YES);
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler(NO);
                                                      }]];
    if(self.controller)
        [self.controller presentViewController:alertController animated:YES completion:^{}];
    
}

-(BOOL)callback_webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType
{
    //back delegate
    return [self.delegate GZCwebView:self shouldStartLoadWithURL:request.URL];
}


#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
#pragma mark - Estimated Progress KVO (WKWebView)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - External App Support
- (BOOL)externalAppRequiredToOpenURL:(NSURL *)URL {
    //若需要限制只允许某些前缀的scheme通过请求，则取消下述注释，并在数组内添加自己需要放行的前缀
    //    NSSet *validSchemes = [NSSet setWithArray:@[@"http", @"https",@"file"]];
    //    return ![validSchemes containsObject:URL.scheme];
    return !URL;
}

- (void)launchExternalAppWithURL:(NSURL *)URL {
    self.URLToLaunchWithPermission = URL;
    if (![self.externalAppPermissionAlertView isVisible]) {
        [self.externalAppPermissionAlertView show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView == self.externalAppPermissionAlertView) {
        if(buttonIndex != alertView.cancelButtonIndex) {
            [[UIApplication sharedApplication] openURL:self.URLToLaunchWithPermission];
        }
        self.URLToLaunchWithPermission = nil;
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    
}

@end
