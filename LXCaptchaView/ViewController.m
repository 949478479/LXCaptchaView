//
//  ViewController.m
//  LXCaptchaView
//
//  Created by 从今以后 on 17/2/7.
//  Copyright © 2017年 从今以后. All rights reserved.
//

#import "ViewController.h"
#import "LXCaptchaView.h"

@interface ViewController ()
@property (nonatomic) IBOutlet LXCaptchaView *captchaView;
@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.captchaView.font = [UIFont boldSystemFontOfSize:12];
	self.captchaView.completion = ^(NSString *captcha){
		NSLog(@"输入完成，验证码：%@", captcha);
	};
}

- (IBAction)beginInputting:(id)sender
{
	[self.captchaView beginInputting];
}

- (IBAction)clearContent:(id)sender
{
	[self.captchaView clearContent];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];

	[self.captchaView endInputting];
}

@end
