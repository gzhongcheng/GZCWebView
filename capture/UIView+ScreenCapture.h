//
//  UIView+ScreenCapture.h
//  MemberSystem
//
//  Created by GuoZhongCheng on 16/7/14.
//  Copyright © 2016年 郭忠橙. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface UIView(ScreenCapture)

@property (nonatomic,assign) BOOL capturing;

- (UIImage *)capture;

- (UIImage *)captureScrollView:(UIScrollView *)scrollView;


@end
