//
//  LXCaptchaView.m
//  LXCaptchaView
//
//  Created by 从今以后 on 17/2/7.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import "LXCaptchaView.h"

@protocol LXTextFieldDelegate <UITextFieldDelegate>
@optional
- (void)textFieldDidDeleteBackward:(UITextField *)textField;
@end

@interface LXTextField : UITextField
@property (nonatomic, weak) id<LXTextFieldDelegate> delegate;
@end
@implementation LXTextField
@dynamic delegate;

- (void)deleteBackward
{
	[super deleteBackward];

	if ([self.delegate respondsToSelector:@selector(textFieldDidDeleteBackward:)]) {
		[self.delegate textFieldDidDeleteBackward:self];
	}
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	return NO;
}

@end

@interface LXCaptchaView () <LXTextFieldDelegate>

@property (nonatomic) BOOL isInputting;
@property (nonatomic) BOOL shouldActivatePreviousTextField;

@property (nonatomic) UIView *coverView;
@property (nonatomic) NSArray<UITextField *> *textFields;

@property (nonatomic) NSMutableArray<NSString *> *inputtedDigits;

@end

@implementation LXCaptchaView

#pragma mark - 构造方法

- (instancetype)init
{
	return [self initWithDigit:4 spacing:8];
}

- (instancetype)initWithDigit:(NSUInteger)digit spacing:(CGFloat)spacing
{
	self = [super initWithFrame:CGRectZero];
	if (self) {
		_digit = digit;
		_spacing = spacing;
		_inputtedDigits = [NSMutableArray new];
		self.backgroundColor = nil;
		[self _setupTextFields];
		[self _setupCoverView];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		_digit = 4;
		_spacing = 8.0;
		_inputtedDigits = [NSMutableArray new];
		self.backgroundColor = nil;
	}
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self _setupTextFields];
	[self _setupCoverView];
}

#pragma mark - 添加输入框

- (void)_setupTextFields
{
	NSUInteger digit = self.digit;
	NSMutableArray *textFields = [NSMutableArray arrayWithCapacity:digit];
	NSMutableArray *constraints = [NSMutableArray new];

	for (NSUInteger i = 0; i < digit; ++i) {

		UITextField *textField = [LXTextField new];
		textField.tag = i;
		textField.delegate = self;
		textField.font = self.font;
		textField.textAlignment = NSTextAlignmentCenter;
		textField.keyboardType = UIKeyboardTypeNumberPad;
		textField.secureTextEntry = self.secureTextEntry;
		textField.borderStyle = UITextBorderStyleRoundedRect;
		textField.translatesAutoresizingMaskIntoConstraints = NO;
		[textField addTarget:self action:@selector(_textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];

		[self addSubview:textField];
		[textFields addObject:textField];

		NSDictionary *metrics = @{ @"spacing" : @(self.spacing) };
		NSDictionary *views = NSDictionaryOfVariableBindings(textField);;
		NSString *visualFormats[2];
		if (i == 0) { // 第一个
			visualFormats[0] = @"H:|[textField]";
			visualFormats[1] = @"V:|[textField]|";
		} else if (i == digit - 1) { // 最后一个
			UITextField *left = textFields[i - 1];
			views = NSDictionaryOfVariableBindings(left, textField);
			visualFormats[0] = @"H:[left]-spacing-[textField]|";
			visualFormats[1] =  @"V:|[textField]|";
		} else { // 中间的
			UITextField *left = textFields[i - 1];
			views = NSDictionaryOfVariableBindings(left, textField);
			visualFormats[0] = @"H:[left]-spacing-[textField]";
			visualFormats[1] =  @"V:|[textField]|";
		}

		for (int i = 0; i < 2; ++i) {
			[constraints addObjectsFromArray:
			 [NSLayoutConstraint constraintsWithVisualFormat:visualFormats[i]
													 options:kNilOptions
													 metrics:metrics
													   views:views]];

		}

		if (i > 0) {
			NSLayoutAttribute attributes[] = { NSLayoutAttributeWidth, NSLayoutAttributeHeight };
			for (int i = 0; i < 2; ++i) {
				[constraints addObject:
				 [NSLayoutConstraint constraintWithItem:textFields[0]
											  attribute:attributes[i]
											  relatedBy:NSLayoutRelationEqual
												 toItem:textField
											  attribute:attributes[i]
											 multiplier:1
											   constant:0]];
			}
		}
	}

	self.textFields = textFields;
	[NSLayoutConstraint activateConstraints:constraints];
}

#pragma mark - 添加轻击手势

- (void)_setupCoverView
{
	UIView *coverView = [UIView new];
	coverView.translatesAutoresizingMaskIntoConstraints = NO;
	self.coverView = coverView;
	[self addSubview:coverView];

	NSDictionary *views = NSDictionaryOfVariableBindings(coverView);
	NSString *visualFormats[] = { @"H:|[coverView]|", @"V:|[coverView]|" };
	for (int i = 0; i < 2; ++i) {
		[NSLayoutConstraint activateConstraints:
		 [NSLayoutConstraint constraintsWithVisualFormat:visualFormats[i]
												 options:kNilOptions
												 metrics:nil
												   views:views]];
	}

	[coverView addGestureRecognizer:
	 [[UITapGestureRecognizer alloc] initWithTarget:self
											 action:@selector(beginInputting)]];
}

#pragma mark - <LXTextFieldDelegate>

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	// 只允许激活由左到右方向上第一个内容为空的输入框
	if (self.inputtedDigits.count == textField.tag) {
		return YES;
	}
	return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	// 删除字符
	if ([string isEqualToString:@""]) {
		return YES;
	}

	// 只允许输入一个数字
	if ([string rangeOfString:@"^\\d$" options:NSRegularExpressionSearch].location != NSNotFound) {
		return YES;
	}

	return NO;
}


- (void)textFieldDidDeleteBackward:(UITextField *)textField
{
	// 左侧还有输入框时，清空左侧输入框内容并激活它
	if (textField.tag > 0) {
		UITextField *previousTextField = self.textFields[textField.tag - 1];
		[previousTextField setText:nil];
		[self _textFieldEditingChanged:previousTextField];
		[previousTextField becomeFirstResponder];
	}
}

- (void)_textFieldEditingChanged:(UITextField *)sender
{
	if (sender.hasText) {
		// 输入了数字，记录数字
		[self.inputtedDigits addObject:sender.text];
		// 激活下一个输入框
		if (sender.tag < self.textFields.count - 1) {
			[self.textFields[sender.tag + 1] becomeFirstResponder];
		} else {
			// 全部输入完毕，关闭键盘，调用完成闭包
			[self endInputting];
			self.completion([self.inputtedDigits componentsJoinedByString:@""]);
		}
	} else {
		// 删除了数字，从记录中移除该数字
		[self.inputtedDigits removeLastObject];
	}
}

#pragma mark - 设置外观

- (void)setDigit:(NSUInteger)digit
{
	// 输入框创建后不允许修改位数
	if (!self.textFields) {
		_digit = digit;
	}
}

- (void)setSpacing:(CGFloat)spacing
{
	// 输入框创建后不允许修改间距
	if (!self.textFields) {
		_spacing = spacing;
	}
}

- (void)setFont:(UIFont *)font
{
	_font = font;

	[self.textFields setValue:font forKey:@"font"];
}

- (void)setCursorColor:(UIColor *)cursorColor
{
	_cursorColor = cursorColor;

	self.tintColor = cursorColor;
}

- (void)setSecureTextEntry:(BOOL)secureTextEntry
{
	_secureTextEntry = secureTextEntry;

	[self.textFields setValue:@(secureTextEntry) forKey:@"secureTextEntry"];
}

#pragma mark - 激活关闭键盘

- (void)beginInputting
{
	if (self.isInputting) {
		return;
	}

	// 输入内容已满，在开启输入前先清空内容
	if (self.inputtedDigits.count == self.digit) {
		[self _clearContent];
	}

	for (UITextField *textField in self.textFields) {
		if ([textField canBecomeFirstResponder]) {
			[textField becomeFirstResponder];
			self.isInputting = YES;
			return;
		}
	}
}

- (void)endInputting
{
	[self endEditing:YES];
	[self setIsInputting:NO];
}

#pragma mark - 清空内容

- (void)_clearContent
{
	[self.inputtedDigits removeAllObjects];
	[self.textFields setValue:nil forKey:@"text"];
}

- (void)clearContent
{
	[self endInputting];
	[self _clearContent];
}

@end
