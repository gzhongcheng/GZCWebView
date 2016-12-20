//
//  GZCActionSheet.h
//  JiuMei
//
//  Created by GuoZhongCheng on 16/6/1.
//  Copyright © 2016年 郭忠橙. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@protocol GZCActionSheetDelegate;
@class UILabel, UIToolbar, UITabBar, UIWindow, UIBarButtonItem, UIPopoverController;

typedef NS_ENUM(NSInteger, GZCActionSheetStyle) {
    GZCActionSheetStyleDefault,             //默认样式，间距相同竖直排列
    GZCActionSheetStyleSystem,              //系统风格，other在上，取消在下分开
    GZCActionSheetStyleScroller,            //图片加文字，横向单行，可滑动
    GZCActionSheetStylePage                 //图片加文字，横向双行，分页
} ;

@interface GZCActionSheet : UIView

@property (nonatomic, strong) UIColor * coverBg;      //遮罩背景
@property (nonatomic, strong) UIColor * actionBg;      //提示框背景
@property (nonatomic, strong) UIColor * cancelBtnTitleColor;      //取消按钮标题颜色
@property (nonatomic, strong) UIColor * cancelBtnBg;      //取消按钮背景
@property (nonatomic, strong) UIColor * cancelBtnBorderColor;      //取消按钮边框颜
@property (nonatomic, strong) UIColor * otherBtnTitleColor;      //取消按钮标题颜色色
@property (nonatomic, strong) UIColor * otherBtnBg;      //其他按钮背景
@property (nonatomic, strong) UIColor * otherBtnBorderColor;      //其他按钮边框颜色

@property(nullable,nonatomic,weak) id<GZCActionSheetDelegate> delegate; //代理
@property(nonatomic,copy) NSString *title;          //提示标题,15号 黑色
@property(nonatomic,copy) NSString *subTitle;          //提示标题，13号 中灰
@property(nonatomic) GZCActionSheetStyle actionSheetStyle; //风格

@property(nonatomic,readonly) NSInteger numberOfButtons;    //共有几个按钮（包括取消）

@property(nonatomic,readonly,getter=isVisible) BOOL visible;//是否已经显示

//GZCActionSheetStyleDefault或GZCActionSheetStyleSystem
- (instancetype)initWithTitle:(nullable NSString *)title subTitle:(nullable NSString*)subTitle delegate:(nullable id<GZCActionSheetDelegate>)delegate cancelButtonTitle:(nullable NSString *)cancelButtonTitle otherButtonTitles:(nullable NSArray<__kindof NSString *>*)otherButtonTitles;
- (NSInteger)addButtonWithTitle:(nullable NSString *)title;

//GZCActionSheetStyleScroller或GZCActionSheetStylePage
- (instancetype)initWithTitle:(nullable NSString *)title subTitle:(nullable NSString*)subTitle delegate:(nullable id<GZCActionSheetDelegate>)delegate cancelButtonTitle:(nullable NSString *)cancelButtonTitle otherButtonTitles:(nullable NSArray<__kindof NSString *>*)otherButtonTitles otherButtonImages:(nullable NSArray<__kindof UIImage *>*)otherButtonImages;
- (NSInteger)addButtonWithTitle:(nullable NSString *)title image:(nullable UIImage*)image;

- (nullable NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;

- (void)showInView:(UIView *)view;

- (void)dismiss:(BOOL)animated;

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@end


@protocol GZCActionSheetDelegate <NSObject>
@optional

- (void)actionSheet:(GZCActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

- (void)actionSheetCancel:(GZCActionSheet *)actionSheet;

- (void)willPresentActionSheet:(GZCActionSheet *)actionSheet;

- (void)didPresentActionSheet:(GZCActionSheet *)actionSheet;

- (void)actionSheet:(GZCActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex;

- (void)actionSheet:(GZCActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end
NS_ASSUME_NONNULL_END
