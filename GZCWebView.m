//
//  GZCWebView.m
//  MemberSystem
//
//  Created by GuoZhongCheng on 16/9/2.
//  Copyright © 2016年 郭忠橙. All rights reserved.
//

#import "GZCWebView.h"
#import "UIView+ScreenCapture.h"
#import "WKWebView+ScreenCapture.h"
#import "GZCActionSheet.h"
#import "UIImageView+WebCache.h"

#define isiOS8 [[[UIDevice currentDevice] systemVersion] floatValue]>=8.0
#define progressTintColor [UIColor colorWithRed:0.400 green:0.863 blue:0.133 alpha:1.000]

static void *GZCWebBrowserContext = &GZCWebBrowserContext;

@interface GZCWebView ()<UIAlertViewDelegate>
@property (nonatomic, strong) NSTimer *fakeProgressTimer;
@property (nonatomic, assign) BOOL uiWebViewIsLoading;
@property (nonatomic, strong) NSURL *uiWebViewCurrentURL;
@property (nonatomic, strong) NSURL *URLToLaunchWithPermission;
@property (nonatomic, strong) UIAlertView *externalAppPermissionAlertView;

@end

@implementation GZCWebView{
    NSString *_saveImageUrl;
}

#pragma mark --Initializers
-(instancetype)initWithFrame:(CGRect)frame{
    return [self initWithFrame:frame cookie:nil];
}

- (instancetype)initWithFrame:(CGRect)frame cookie:(NSArray *)cookie
{
    self = [super initWithFrame:frame];
    if (self) {
        if(isiOS8) {
            if ([cookie count]) {
                self.wkWebView = [[WKWebView alloc]initWithFrame:frame configuration:[self getconfigurationWithCookies:cookie]];
            }else{
                self.wkWebView = [[WKWebView alloc] init];
            }
        }
        else {
            self.uiWebView = [[UIWebView alloc] init];
            
        }
        self.backgroundColor = [UIColor redColor];
        if(self.wkWebView) {
            [self.wkWebView setFrame:frame];
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
        }
        else  {
            [self.uiWebView setFrame:frame];
            [self.uiWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
            [self.uiWebView setDelegate:self];
            [self.uiWebView setMultipleTouchEnabled:YES];
            [self.uiWebView setAutoresizesSubviews:YES];
            [self.uiWebView setScalesPageToFit:YES];
            [self.uiWebView.scrollView setAlwaysBounceVertical:YES];
            self.uiWebView.scrollView.bounces = NO;
            [self addSubview:self.uiWebView];
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(uiLongPressed:)];
            longPress.delegate = self;
            [self.wkWebView addGestureRecognizer:longPress];
        }
        
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
    if (isiOS8) {
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
}

+ (void)deleteWebCache {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        //// All kinds of data
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        //// Date from
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        //// Execute
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            // Done
        }];
        
    } else {
        
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
        NSError *errors;
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
        
    }
}

-(NSString *)getWebTitle{
    NSString *title = @"";
    if (isiOS8) {
        title = self.wkWebView.title;
    }else{
        title = [self.uiWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    return title;
}

-(void)reload{
    if (isiOS8){
        [self.wkWebView reload];
    }else{
        [self.uiWebView reload];
    }
}

-(BOOL)canGoBack{
    if (isiOS8) {
        if (self.wkWebView.canGoBack) {
            [self.wkWebView goBack];
            return YES;
        }else {
            return NO;
        }
    }else {
        if (self.uiWebView.canGoBack) {
            [self.uiWebView goBack];
            return YES;
        }else {
            return NO;
        }
    }
}

-(NSURL *)getURL{
    NSURL *url;
    if (isiOS8)
        url = self.wkWebView.URL;
    else
        url = self.uiWebView.request.URL;
    return url;
}

-(void)getCapture:(void (^)(UIImage *))completionHandler{
    if (isiOS8)
       [self.wkWebView captureCallback:^(UIImage * _Nullable capturedImage) {
           completionHandler(capturedImage);
        }];
    else{
        UIImage *capture = [self.uiWebView capture];
        completionHandler(capture);
    }
}

-(void)clearCookie:(NSURL *)url{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookieAry = [cookieJar cookies];
    for (cookie in cookieAry) {
        [cookieJar deleteCookie: cookie];
    }
    if (isiOS8) {
        [self updateCookie:nil url:url];
    }
}

-(void)getCookieString:(void (^)(NSString *))completionHandle{
    if(isiOS8){
        [self.wkWebView evaluateJavaScript:@"document.cookie" completionHandler:^(id _Nullable message, NSError * _Nullable error) {
            completionHandle(message);
        }];
    }else{
        NSString *message = [self.uiWebView stringByEvaluatingJavaScriptFromString:@"document.cookie"];
        completionHandle(message);
    }
}

- (void)loadRequest:(NSURLRequest *)request {
    if(self.wkWebView) {
        [self.wkWebView loadRequest:request];
    }
    else  {
        [self.uiWebView loadRequest:request];
    }
}

-(void)loadRequest:(NSURLRequest *)request withCookie:(NSDictionary *)cookies{
    if (self.cookies != cookies) {
        self.cookies = cookies;
    }
    if(self.wkWebView) {
        NSMutableURLRequest *mrequest = [NSMutableURLRequest requestWithURL:request.URL];
        NSString *cookie = [self readCurrentCookie];
        for (NSString *key in [cookies allKeys]) {
            if ([cookie rangeOfString:key].length == 0) {
                cookie = [NSString stringWithFormat:@"%@;%@=%@",cookie,key,[cookies objectForKey:key]];
            }
        }
        [mrequest addValue:cookie forHTTPHeaderField:@"Cookie"];
        [self.wkWebView loadRequest:mrequest];
    }
    else  {
        [self.uiWebView loadRequest:request];
    }
}

- (void)loadURL:(NSURL *)URL {
    [self loadRequest:[NSURLRequest requestWithURL:URL]];
}

-(void)loadURL:(NSURL *)URL withCookie:(NSDictionary *)cookies{
    [self loadRequest:[NSURLRequest requestWithURL:URL] withCookie:cookies];
}

- (void)loadURLString:(NSString *)URLString {
    NSURL *URL = [NSURL URLWithString:URLString];
    [self loadURL:URL];
}

-(void)loadURLString:(NSString *)URLString withCookie:(NSDictionary *)cookies{
    NSURL *URL = [NSURL URLWithString:URLString];
    [self loadURL:URL withCookie:cookies];
}

- (void)loadHTMLString:(NSString *)HTMLString {
    if(self.wkWebView) {
        [self.wkWebView loadHTMLString:HTMLString baseURL:nil];
    }
    else if(self.uiWebView) {
        [self.uiWebView loadHTMLString:HTMLString baseURL:nil];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self.progressView setTintColor:tintColor];
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    _barTintColor = barTintColor;
}

- (WKWebViewConfiguration *)getconfigurationWithCookies:(NSArray *)cookies{
    if ([cookies count]) {
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

- (NSString *)readCurrentCookie{
    NSHTTPCookieStorage*cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableString *cookieString = [[NSMutableString alloc] init];
    if ([[cookieJar cookies]count]) {
        for (NSHTTPCookie*cookie in [cookieJar cookies]) {
            //多个字段之间用“；”隔开
            [cookieString appendFormat:@"%@=%@;",cookie.name,cookie.value];
        }
        //删除最后一个“；”
        [cookieString deleteCharactersInRange:NSMakeRange(cookieString.length - 1, 1)];
    }
    return cookieString;
}

#pragma mark - target
- (void)uiLongPressed:(UILongPressGestureRecognizer*)recognizer
{
    if (!self.shouldLontTapImage||recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint touchPoint = [recognizer locationInView:self.uiWebView];
    
    NSString *imgURL = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
    NSString *urlToSave = [self.uiWebView stringByEvaluatingJavaScriptFromString:imgURL];
    
    if (urlToSave.length == 0) {
        return;
    }
    
    [self showImageOptionsWithUrl:urlToSave];
}

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
        [self showImageOptionsWithUrl:imgUrl];
    }];
}

-(void)showImageOptionsWithUrl:(NSString *)imgUrl{
    if (imgUrl) {
        _saveImageUrl = imgUrl;
        GZCActionSheet *actionSheet = [[GZCActionSheet alloc]initWithTitle:nil
                                                                  subTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"取消"
                                                         otherButtonTitles:@[@"保存图片",@"分享链接"]
                                                         otherButtonImages:nil];
        
        [actionSheet showInView:self.superview];
    }
}


#pragma mark - actionSheetDelegate
-(void)actionSheet:(GZCActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
        {
            [[SDWebImageManager sharedManager]downloadImageWithURL:[NSURL URLWithString:_saveImageUrl] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                if (image==nil) {
                    if ([self.delegate respondsToSelector:@selector(GZCWebView:didSavedImage:)]) {
                        [self.delegate GZCWebView:self didSavedImage:@"保存图片失败！"];
                    }
                    return;
                }
                UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            }];
        }
            break;
        case 1:
        {
            if ([self.delegate respondsToSelector:@selector(GZCWebView:didLongTapShared:)]) {
                [self.delegate GZCWebView:self didLongTapShared:_saveImageUrl];
            }
        }
        default:
            break;
    }
}

#pragma mark - imageSaved
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSString *message = @"图片已成功保存到相册！";
    if (error) {
        message = @"保存图片失败！";
    }
    if ([self.delegate respondsToSelector:@selector(GZCWebView:didSavedImage:)]) {
        [self.delegate GZCWebView:self didSavedImage:message];
    }
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if(webView == self.uiWebView) {
        [self.delegate GZCwebViewDidStartLoad:self];
        
    }
}

//监视请求
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if(webView == self.uiWebView) {
        if(![self externalAppRequiredToOpenURL:request.URL]) {
            self.uiWebViewCurrentURL = request.URL;
            self.uiWebViewIsLoading = YES;
            
            [self fakeProgressViewStartLoading];
            
            //back delegate
            [self.delegate GZCwebView:self shouldStartLoadWithURL:request.URL];
            return YES;
        }
        else {
            [self launchExternalAppWithURL:request.URL];
            return NO;
        }
    }
    return NO;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if(webView == self.uiWebView) {
        if(!self.uiWebView.isLoading) {
            self.uiWebViewIsLoading = NO;
            
            [self fakeProgressBarStopLoading];
        }
        
        //back delegate
        [self.delegate GZCwebView:self didFinishLoadingURL:self.uiWebView.request.URL];
        
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(webView == self.uiWebView) {
        if(!self.uiWebView.isLoading) {
            self.uiWebViewIsLoading = NO;
            
            [self fakeProgressBarStopLoading];
        }
        
        //back delegate
        [self.delegate GZCwebView:self didFailToLoadURL:self.uiWebView.request.URL error:error];
    }
}


#pragma mark - WKNavigationDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if(webView == self.wkWebView) {
        //back delegate
        [self.delegate GZCwebViewDidStartLoad:self];
        //        WKNavigationActionPolicy(WKNavigationActionPolicyAllow);
        
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if(webView == self.wkWebView) {
        
        //back delegate
        [self.delegate GZCwebView:self didFinishLoadingURL:self.wkWebView.URL];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView) {
        //back delegate
        [self.delegate GZCwebView:self didFailToLoadURL:self.wkWebView.URL error:error];
    }
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView) {
        //back delegate
        [self.delegate GZCwebView:self didFailToLoadURL:self.wkWebView.URL error:error];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if(webView == self.wkWebView) {
        NSURL *URL = navigationAction.request.URL;
        if(![self externalAppRequiredToOpenURL:URL]) {
            if(!navigationAction.targetFrame) {
                [self loadURL:URL withCookie:self.cookies];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            if(![self callback_webViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType]){
                decisionHandler(WKNavigationActionPolicyCancel);
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

#pragma mark - Fake Progress Bar Control (UIWebView)

- (void)fakeProgressViewStartLoading {
    [self.progressView setProgress:0.0f animated:NO];
    [self.progressView setAlpha:1.0f];
    
    if(!self.fakeProgressTimer) {
        self.fakeProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f target:self selector:@selector(fakeProgressTimerDidFire:) userInfo:nil repeats:YES];
    }
}

- (void)fakeProgressBarStopLoading {
    if(self.fakeProgressTimer) {
        [self.fakeProgressTimer invalidate];
    }
    
    if(self.progressView) {
        [self.progressView setProgress:1.0f animated:YES];
        [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.progressView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [self.progressView setProgress:0.0f animated:NO];
        }];
    }
}

- (void)fakeProgressTimerDidFire:(id)sender {
    CGFloat increment = 0.005/(self.progressView.progress + 0.2);
    if([self.uiWebView isLoading]) {
        CGFloat progress = (self.progressView.progress < 0.75f) ? self.progressView.progress + increment : self.progressView.progress + 0.0005;
        if(self.progressView.progress < 0.95) {
            [self.progressView setProgress:progress animated:YES];
        }
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
    [self.uiWebView setDelegate:nil];
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    
}

@end
