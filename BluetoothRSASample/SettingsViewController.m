//
//  SettingsViewController.m
//  BTLE Transfer
//
//  Created by naru on 2015/10/28.
//  Copyright © 2015年 Apple. All rights reserved.
//

#import "SettingsViewController.h"

static CGFloat kTextFiledFontSize = 15.0f;
static CGSize kTextFieldSize = (CGSize){260.0f, 30.0f};

static CGFloat kItemsSpacing = 24.0f;
static CGSize kButtonSize = (CGSize){200.f, 44.0f};

@interface SettingsViewController ()
@property (nonatomic) UITextField *publicKey1TextFiled;
@property (nonatomic) UITextField *publicKey2TextFiled;
@property (nonatomic) UITextField *secretKeyTextFiled;
@property (nonatomic) UIButton *saveButton;
@property (nonatomic) UIButton *closeButton;
@end

@implementation SettingsViewController

#pragma mark - action

- (void)onSaveButtonClicked:(UIButton *)sender {
    [_publicKey1TextFiled resignFirstResponder];
    [_publicKey2TextFiled resignFirstResponder];
    [_secretKeyTextFiled resignFirstResponder];
    
    [[NSUserDefaults standardUserDefaults] setObject:_publicKey1TextFiled.text forKey:@"public1"];
    [[NSUserDefaults standardUserDefaults] setObject:_publicKey2TextFiled.text forKey:@"public2"];
    [[NSUserDefaults standardUserDefaults] setObject:_secretKeyTextFiled.text forKey:@"secret"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [_saveButton setTitle:@"保存しました" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_saveButton setTitle:@"保存" forState:UIControlStateNormal];
    });
}

- (void)onCloseButtonClicked:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithWhite:0.92f alpha:1.0f]];
    
    [self.view addSubview:self.publicKey1TextFiled];
    [self.view addSubview:self.publicKey2TextFiled];
    [self.view addSubview:self.secretKeyTextFiled];
    [self.view addSubview:self.saveButton];
    [self.view addSubview:self.closeButton];
}

- (UITextField *)publicKey1TextFiled {
    if (_publicKey1TextFiled) return _publicKey1TextFiled;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kTextFieldSize.width)/2.0f, 200.0f, kTextFieldSize.width, kTextFieldSize.height);
    _publicKey1TextFiled = [[UITextField alloc] initWithFrame:frame];
    [_publicKey1TextFiled setFont:[UIFont systemFontOfSize:kTextFiledFontSize]];
    [_publicKey1TextFiled setBackgroundColor:[UIColor whiteColor]];
    [_publicKey1TextFiled.layer setBorderWidth:0.5f];
    [_publicKey1TextFiled.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [_publicKey1TextFiled setPlaceholder:@"公開鍵1 (e_i = 13)"];
    [_publicKey1TextFiled setKeyboardType:UIKeyboardTypeNumberPad];
    [_publicKey1TextFiled setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 4.0f, kTextFieldSize.height)]];
    [_publicKey1TextFiled setLeftViewMode:UITextFieldViewModeAlways];
    [_publicKey1TextFiled setText:[[NSUserDefaults standardUserDefaults] valueForKey:@"public1"]];
    return _publicKey1TextFiled;
}

- (UITextField *)publicKey2TextFiled {
    if (_publicKey2TextFiled) return _publicKey2TextFiled;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kTextFieldSize.width)/2.0f, CGRectGetMaxY(_publicKey1TextFiled.frame)+kItemsSpacing, kTextFieldSize.width, kTextFieldSize.height);
    _publicKey2TextFiled = [[UITextField alloc] initWithFrame:frame];
    [_publicKey2TextFiled setFont:[UIFont systemFontOfSize:kTextFiledFontSize]];
    [_publicKey2TextFiled setBackgroundColor:[UIColor whiteColor]];
    [_publicKey2TextFiled.layer setBorderWidth:0.5f];
    [_publicKey2TextFiled.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [_publicKey2TextFiled setPlaceholder:@"公開鍵2 (N = 437)"];
    [_publicKey2TextFiled setKeyboardType:UIKeyboardTypeNumberPad];
    [_publicKey2TextFiled setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 4.0f, kTextFieldSize.height)]];
    [_publicKey2TextFiled setLeftViewMode:UITextFieldViewModeAlways];
    [_publicKey2TextFiled setText:[[NSUserDefaults standardUserDefaults] valueForKey:@"public2"]];
    return _publicKey2TextFiled;
}

- (UITextField *)secretKeyTextFiled {
    if (_secretKeyTextFiled) return _secretKeyTextFiled;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kTextFieldSize.width)/2.0f, CGRectGetMaxY(_publicKey2TextFiled.frame)+kItemsSpacing, kTextFieldSize.width, kTextFieldSize.height);
    _secretKeyTextFiled = [[UITextField alloc] initWithFrame:frame];
    [_secretKeyTextFiled setFont:[UIFont systemFontOfSize:kTextFiledFontSize]];
    [_secretKeyTextFiled setBackgroundColor:[UIColor whiteColor]];
    [_secretKeyTextFiled.layer setBorderWidth:0.5f];
    [_secretKeyTextFiled.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [_secretKeyTextFiled setPlaceholder:@"秘密鍵 (d_i = 61)"];
    [_secretKeyTextFiled setKeyboardType:UIKeyboardTypeNumberPad];
    [_secretKeyTextFiled setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 4.0f, kTextFieldSize.height)]];
    [_secretKeyTextFiled setLeftViewMode:UITextFieldViewModeAlways];
    [_secretKeyTextFiled setText:[[NSUserDefaults standardUserDefaults] valueForKey:@"secret"]];
    return _secretKeyTextFiled;
}

- (UIButton *)saveButton {
    if (_saveButton) return _saveButton;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kButtonSize.width)/2.0f, CGRectGetMaxY(_secretKeyTextFiled.frame)+kItemsSpacing, kButtonSize.width, kButtonSize.height);
    _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_saveButton setFrame:frame];
    [_saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [_saveButton addTarget:self action:@selector(onSaveButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_saveButton setShowsTouchWhenHighlighted:YES];
    return _saveButton;
}

- (UIButton *)closeButton {
    if (_closeButton) return _closeButton;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kButtonSize.width)/2.0f, CGRectGetHeight(self.view.frame)-kButtonSize.height, kButtonSize.width, kButtonSize.height);
    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_closeButton setFrame:frame];
    [_closeButton setTitle:@"閉じる" forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(onCloseButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return _closeButton;
}

#pragma mark - touch

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_publicKey1TextFiled resignFirstResponder];
    [_publicKey2TextFiled resignFirstResponder];
    [_secretKeyTextFiled resignFirstResponder];
}

@end
