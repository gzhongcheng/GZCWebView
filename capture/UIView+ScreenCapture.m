//
//  UIView+ScreenCapture.m
//  MemberSystem
//
//  Created by GuoZhongCheng on 16/7/14.
//  Copyright © 2016年 郭忠橙. All rights reserved.
//

#import "UIView+ScreenCapture.h"
#import "GZCConstant.h"
#import <objc/runtime.h>

@implementation UIView(ScreenCapture)

char kCapturing;

-(void)setCapturing:(BOOL)capturing{
    objc_setAssociatedObject(self, &kCapturing, @(capturing), OBJC_ASSOCIATION_ASSIGN);
}

-(BOOL)capturing{
    return (BOOL)objc_getAssociatedObject(self, &kCapturing);
}

-(UIImage *)capture{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef currnetContext = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:currnetContext];
    // 从当前context中创建一个改变大小后的图片
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)captureScrollView:(UIScrollView *)scrollView{
    UIImage* image = nil;
    UIGraphicsBeginImageContextWithOptions(scrollView.contentSize,  NO, [UIScreen mainScreen].scale);
    {
        CGPoint savedContentOffset = scrollView.contentOffset;
        CGRect savedFrame = scrollView.frame;
        scrollView.contentOffset = CGPointZero;
        scrollView.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
        
        [scrollView.layer renderInContext: UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        scrollView.contentOffset = savedContentOffset;
        scrollView.frame = savedFrame;
    }
    UIGraphicsEndImageContext();
    
    if (image != nil) {
        return image;
    }
    return nil;
}



@end
