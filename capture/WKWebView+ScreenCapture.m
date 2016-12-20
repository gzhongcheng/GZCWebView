//
//  WKWebView+ScreenCapture.m
//  FilmCrowdFunding
//
//  Created by ZhongCheng Guo on 2016/12/12.
//  Copyright © 2016年 ZhongCheng Guo. All rights reserved.
//

#import "WKWebView+ScreenCapture.h"
#import "GZCFramework.h"
#import "UIView+ScreenCapture.h"

@implementation WKWebView(ScreenCapture)

-(void)captureCallback:(void(^)(UIImage * image))callback{
    self.capturing = YES;
    CGPoint offset = self.scrollView.contentOffset;
    UIView * snapShotView = [self snapshotViewAfterScreenUpdates:YES];
    snapShotView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, snapShotView.frame.size.width, snapShotView.frame.size.height);
    [self.superview addSubview:snapShotView];
    if (self.frame.size.height < self.scrollView.contentSize.height) {
        self.scrollView.contentOffset = CGPointMake(0, self.scrollView.contentSize.height - self.frame.size.height);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.scrollView.contentOffset = CGPointZero;
        [self contentCaptureWithoutOffsetCallback:^(UIImage *image) {
            self.scrollView.contentOffset = offset;
            [snapShotView removeFromSuperview];
            self.capturing = NO;
            callback(image);
        }];
    });
}

-(void)contentCaptureWithoutOffsetCallback:(void(^)(UIImage * image))callback{
    UIView *containerView = [[UIView alloc]initWithFrame:self.bounds];
    
    CGRect bakFrame = self.frame;
    UIView *bakSuperView = self.superview;
    NSUInteger bakIndex = [self.superview.subviews indexOfObject:self];
    [self removeFromSuperview];
    [containerView addSubview:self];
    
    CGSize totalSize = self.scrollView.contentSize;
    int page = floorf(totalSize.height/(float)containerView.bounds.size.height);
    self.frame = CGRectMake(0, 0, containerView.bounds.size.width, self.scrollView.contentSize.height);
    
    UIGraphicsBeginImageContextWithOptions(totalSize,  NO, [UIScreen mainScreen].scale);
    [self contentPageDrawWithTargetView:containerView atIndex:0 maxIndex:page callback:^{
        UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self removeFromSuperview];
        [bakSuperView insertSubview:self atIndex:bakIndex];
        self.frame = bakFrame;
        [containerView removeFromSuperview];
        callback(capturedImage);
    }];
}

-(void)contentPageDrawWithTargetView:(UIView *)targetView
               atIndex:(NSInteger)index
              maxIndex:(NSInteger)maxIndex
              callback:(void(^)())callback{
    CGRect splitFrame = CGRectMake(0, index * targetView.frame.size.height, targetView.bounds.size.width, targetView.bounds.size.height);
    CGRect myFrame = self.frame;
    myFrame.origin.y = - (index * targetView.frame.size.height);
    self.frame = myFrame;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [targetView drawViewHierarchyInRect:splitFrame afterScreenUpdates:YES];
        if (index<maxIndex) {
            [self contentPageDrawWithTargetView:targetView atIndex:index + 1 maxIndex:maxIndex callback:callback];
        }else{
            callback();
        }
    });
}

@end
