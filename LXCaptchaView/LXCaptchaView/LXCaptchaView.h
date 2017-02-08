//
//  LXCaptchaView.h
//  LXCaptchaView
//
//  Created by 从今以后 on 17/2/7.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXCaptchaView : UIView

/// 默认 8.0，仅供界面编辑器设置
@property (nonatomic) IBInspectable CGFloat spacing;
/// 默认 4 位，仅供界面编辑器设置
@property (nonatomic) IBInspectable NSUInteger digit;

/// 默认 12.0 系统字体
@property (nonatomic) UIFont *font;
/// 光标颜色，默认为系统默认颜色
@property (nonatomic) IBInspectable UIColor *cursorColor;
/// 默认为 NO
@property (nonatomic) IBInspectable BOOL secureTextEntry;

/// 输入完成
@property (nonatomic) void (^completion)(NSString *captcha);

- (instancetype)initWithDigit:(NSUInteger)digit spacing:(CGFloat)spacing;

/// 开启键盘
- (void)beginInputting;
/// 关闭键盘
- (void)endInputting;
/// 清空内容并关闭键盘
- (void)clearContent;

@end
