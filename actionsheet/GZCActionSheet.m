//
//  GZCActionSheet.m
//  JiuMei
//
//  Created by GuoZhongCheng on 16/6/1.
//  Copyright © 2016年 郭忠橙. All rights reserved.
//

#import "GZCActionSheet.h"
#import "GZCFramework.h"
#import "UIImage+Blur.h"

@implementation GZCActionSheet{
    NSMutableArray *buttonTitles;
    NSMutableArray *buttonImages;
    NSString *cancelBtnTitle;
    UIView *actionView;
    BOOL isShow;
}

-(instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle delegate:(id<GZCActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray<__kindof NSString *> *)otherButtonTitles{
    return [self initWithTitle:title subTitle:subTitle delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles otherButtonImages:nil];
}

-(instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle delegate:(id<GZCActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray<__kindof NSString *> *)otherButtonTitles otherButtonImages:(NSArray<__kindof UIImage *> *)otherButtonImages{
    if (self = [super initWithFrame:CGRectMake(0, 0, mainWidth, mainHeight)]) {
        self.title = title;
        self.delegate = delegate;
        cancelBtnTitle = cancelButtonTitle;
        self.subTitle = subTitle;
        buttonTitles = [NSMutableArray arrayWithArray:otherButtonTitles];
        buttonImages = [NSMutableArray arrayWithArray:otherButtonImages];
        self.coverBg = [UIColor colorWithWhite:.3f alpha:.5f];
        self.actionBg = [UIColor whiteColor];
        self.cancelBtnTitleColor = [UIColor redColor];
        self.cancelBtnBg = [UIColor whiteColor];
        self.cancelBtnBorderColor = [UIColor redColor];
        self.otherBtnBg = [UIColor whiteColor];
        self.otherBtnBorderColor = [UIColor blackColor];
        self.otherBtnTitleColor = [UIColor blackColor];
        
        actionView = [[UIView alloc]initWithFrame:CGRectMake(0, HEIGHT(self), WIDTH(self), 200)];
        [self addSubview:actionView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bgTaped)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

-(void)bgTaped{
    [self dismiss:YES];
}

-(void)updateViews{
    for (UIView *view in [actionView subviews]) {
        [view removeFromSuperview];
    }
    actionView.backgroundColor = self.actionBg;
    float offy = 15;
    if (self.title!=nil) {
        UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, offy, mainWidth-30, 20)];
        titleLabel.font = [UIFont systemFontOfSize:15];
        titleLabel.textColor = mainBlackFontColor;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = self.title;
        titleLabel.numberOfLines = 0;
        [actionView addSubview:titleLabel];
        [titleLabel sizeToFit];
        titleLabel.frame = RECT_CHANGE_width(titleLabel, mainWidth-30);
        offy += HEIGHT(titleLabel)+10;
    }
    if (self.subTitle!=nil) {
        UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, offy, mainWidth-30, 20)];
        titleLabel.font = [UIFont systemFontOfSize:13];
        titleLabel.textColor = mainFontColor;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = self.subTitle;
        titleLabel.numberOfLines = 0;
        [actionView addSubview:titleLabel];
        [titleLabel sizeToFit];
        titleLabel.frame = RECT_CHANGE_width(titleLabel, mainWidth-30);
        offy += HEIGHT(titleLabel)+10;
    }
    switch (self.actionSheetStyle) {
        case GZCActionSheetStyleDefault:
        {
            int tag = 0;
            for (NSString *title in buttonTitles) {
                UIButton *button = [self buttonWithTitle:title titleColor:self.otherBtnTitleColor bgColor:self.otherBtnBg borderColor:self.otherBtnBorderColor frame:CGRectMake(15, offy, mainWidth-30, 40) tag:tag];
                [button addTarget:self action:@selector(otherBtnTaped:) forControlEvents:UIControlEventTouchUpInside];
                [actionView addSubview:button];
                offy += 55;
                tag ++;
            }
            UIButton *cancelButton = [self buttonWithTitle:cancelBtnTitle titleColor:self.cancelBtnTitleColor bgColor:self.cancelBtnBg borderColor:self.cancelBtnBorderColor frame:CGRectMake(15, offy, mainWidth-30, 40) tag:tag];
            [cancelButton addTarget:self action:@selector(cancelBtnTaped:) forControlEvents:UIControlEventTouchUpInside];
            [actionView addSubview:cancelButton];
            
            actionView.frame = RECT_CHANGE_height(actionView, MaxY(cancelButton)+15);
        }
            break;
        case GZCActionSheetStyleSystem:
        {
            actionView.backgroundColor = [UIColor clearColor];
            int tag = 0;
            UIView *btnsBg = [[UIView alloc]initWithFrame:CGRectMake(15, offy, mainWidth-30, 0)];
            btnsBg.layer.cornerRadius = 4.f;
            btnsBg.clipsToBounds = YES;
            float btnOffy = 0;
            for (NSString *title in buttonTitles) {
                UIButton *button = [self buttonWithTitle:title titleColor:self.otherBtnTitleColor bgColor:self.otherBtnBg borderColor:self.otherBtnBorderColor frame:CGRectMake(0, btnOffy, mainWidth-30, 40) tag:tag];
                
                button.layer.cornerRadius = 0;
                [button addTarget:self action:@selector(otherBtnTaped:) forControlEvents:UIControlEventTouchUpInside];
                [btnsBg addSubview:button];
                btnOffy += 41;
                tag ++;
            }
            btnsBg.frame = RECT_CHANGE_height(btnsBg, btnOffy-1);
            offy += HEIGHT(btnsBg) + 10;
            [actionView addSubview:btnsBg];
            
            UIButton *cancelButton = [self buttonWithTitle:cancelBtnTitle titleColor:self.cancelBtnTitleColor bgColor:self.cancelBtnBg borderColor:self.cancelBtnBorderColor frame:CGRectMake(15, offy, mainWidth-30, 40) tag:tag];
            cancelButton.layer.cornerRadius = 4.f;
            [cancelButton addTarget:self action:@selector(cancelBtnTaped:) forControlEvents:UIControlEventTouchUpInside];
            [actionView addSubview:cancelButton];
            
            actionView.frame = RECT_CHANGE_height(actionView, MaxY(cancelButton)+15);
        }
            break;
        case GZCActionSheetStylePage:
        {
            
        }
            break;
        case GZCActionSheetStyleScroller:
        {
            
        }
            break;
    }
    
}

-(UIButton*)buttonWithTitle:(NSString *)title titleColor:(UIColor*)titleColor bgColor:(UIColor*)bgColor borderColor:(UIColor*)borderColor frame:(CGRect)frame tag:(int)tag{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    [button setBackgroundColor:bgColor];
    button.frame = frame;
    button.layer.cornerRadius = 8;
    button.layer.borderColor = borderColor.CGColor;
    button.layer.borderWidth = 1;
    button.clipsToBounds = YES;
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    button.tag = tag;
    return button;
}

-(void)otherBtnTaped:(UIButton *)btn{
    [self dismissWithClickedButtonIndex:btn.tag animated:YES];
}

-(void)cancelBtnTaped:(UIButton *)btn{
    [self dismiss:YES];
    if ([self.delegate respondsToSelector:@selector(actionSheetCancel:)]) {
        [self.delegate actionSheetCancel:self];
    }
}

-(NSInteger)addButtonWithTitle:(NSString *)title{
    [buttonTitles addObject:title];
    return [buttonTitles count];
}

-(NSInteger)addButtonWithTitle:(NSString *)title image:(UIImage *)image{
    [buttonTitles addObject:title];
    [buttonImages addObject:image];
    return [buttonTitles count];
}

-(NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == [buttonTitles count]) {
        return cancelBtnTitle;
    }
    return buttonTitles[buttonIndex];
}

-(NSInteger)numberOfButtons{
    return [buttonTitles count]+1;
}

-(void)showInView:(UIView *)view{
    if (isShow) {
        return;
    }
    self.frame = view.bounds;
    self.backgroundColor = CHANGE_COLOR_ALPHA(self.coverBg,0);
    actionView.frame = RECT_CHANGE_y(actionView, HEIGHT(self));
    [view addSubview:self];
    [view bringSubviewToFront:self];
    isShow = YES;
    [self updateViews];
    [UIView animateWithDuration:.2f animations:^{
        self.backgroundColor = self.coverBg;
        actionView.frame = RECT_CHANGE_y(actionView, HEIGHT(self)-HEIGHT(actionView));
    }];
}


-(BOOL)isVisible{
    return isShow;
}

-(void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated{
    if ([self.delegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)]) {
        [self.delegate actionSheet:self willDismissWithButtonIndex:buttonIndex];
    }
    if ([self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)]) {
        [self.delegate actionSheet:self clickedButtonAtIndex:buttonIndex];
    }
    [self dismiss:animated];
    if ([self.delegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)]) {
        [self.delegate actionSheet:self didDismissWithButtonIndex:buttonIndex];
    }
}

-(void)dismiss:(BOOL)animated{
    float dur = 0.f;
    if (animated) {
        dur = .2f;
    }
    [UIView animateWithDuration:dur animations:^{
        self.backgroundColor = CHANGE_COLOR_ALPHA(self.coverBg,0);
        actionView.frame = RECT_CHANGE_y(actionView, HEIGHT(self));
    }completion:^(BOOL finished) {
        [self removeFromSuperview];
        isShow = NO;
    }];
}

@end
