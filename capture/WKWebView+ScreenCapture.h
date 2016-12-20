//
//  WKWebView+ScreenCapture.h
//  FilmCrowdFunding
//
//  Created by ZhongCheng Guo on 2016/12/12.
//  Copyright © 2016年 ZhongCheng Guo. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView(ScreenCapture)

- (void)captureCallback:(void(^)(UIImage * image))callback;

@end
