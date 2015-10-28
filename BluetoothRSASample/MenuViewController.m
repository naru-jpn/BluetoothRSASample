//
//  MenuViewController.m
//  BTLE Transfer
//
//  Created by naru on 2015/10/27.
//  Copyright © 2015年 Apple. All rights reserved.
//

#import "MenuViewController.h"
#import "ReceiveMessageViewController.h"
#import "SendMessageViewController.h"
#import "ReceivePublicKeyViewController.h"
#import "SendPublicKeyViewController.h"
#import "SettingsViewController.h"

static CGSize kButtonSize = (CGSize){200.0f, 44.0f};
static CGSize kInfoButtonSize = (CGSize){36.0f, 36.0f};

static CGFloat kItemsSpacing = 24.0f;
static CGFloat kLayoutSpacing = 12.0f;

@interface MenuViewController ()
@property (nonatomic) UIButton *centralButton;
@property (nonatomic) UIButton *peripheralButton;
@property (nonatomic) UIButton *receiveKeyButton;
@property (nonatomic) UIButton *sendKeyButton;
@property (nonatomic) UIButton *infoButton;
@end

@implementation MenuViewController

#pragma mark - action

- (void)onCentralButtonClicked:(UIButton *)sender {
    [self.navigationController pushViewController:[ReceiveMessageViewController new] animated:YES];
}

- (void)onPeripheralButtonClicked:(UIButton *)sender {
    [self.navigationController pushViewController:[SendMessageViewController new] animated:YES];
}

- (void)onReceiveKeyButtonClicked:(UIButton *)sender {
    [self.navigationController pushViewController:[ReceivePublicKeyViewController new] animated:YES];
}

- (void)onSendKeyButtonClicked:(UIButton *)sender {
    [self.navigationController pushViewController:[SendPublicKeyViewController new] animated:YES];
}

- (void)onInfoButtonClicked:(UIButton *)sender {
    [self presentViewController:[SettingsViewController new] animated:YES completion:nil];
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"メニュー"];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
    [self.view addSubview:self.sendKeyButton];
    [self.view addSubview:self.receiveKeyButton];
    [self.view addSubview:self.peripheralButton];
    [self.view addSubview:self.centralButton];
    [self.view addSubview:self.infoButton];
}

- (UIButton *)sendKeyButton {
    if (_sendKeyButton) return _sendKeyButton;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kButtonSize.width)/2.0f, 140.0f, kButtonSize.width, kButtonSize.height);
    _sendKeyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_sendKeyButton setFrame:frame];
    [_sendKeyButton setTitle:@"公開鍵を送る" forState:UIControlStateNormal];
    [_sendKeyButton addTarget:self action:@selector(onSendKeyButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return _sendKeyButton;
}

- (UIButton *)receiveKeyButton {
    if (_receiveKeyButton) return _receiveKeyButton;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kButtonSize.width)/2.0f, CGRectGetMaxY(_sendKeyButton.frame)+kItemsSpacing, kButtonSize.width, kButtonSize.height);
    _receiveKeyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_receiveKeyButton setFrame:frame];
    [_receiveKeyButton setTitle:@"公開鍵を受け取る" forState:UIControlStateNormal];
    [_receiveKeyButton addTarget:self action:@selector(onReceiveKeyButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return _receiveKeyButton;
}

- (UIButton *)peripheralButton {
    if (_peripheralButton) return _peripheralButton;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kButtonSize.width)/2.0f, CGRectGetMaxY(_receiveKeyButton.frame)+kItemsSpacing, kButtonSize.width, kButtonSize.height);
    _peripheralButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_peripheralButton setFrame:frame];
    [_peripheralButton setTitle:@"暗号文を送る" forState:UIControlStateNormal];
    [_peripheralButton addTarget:self action:@selector(onPeripheralButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return _peripheralButton;
}

- (UIButton *)centralButton {
    if (_centralButton) return _centralButton;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kButtonSize.width)/2.0f, CGRectGetMaxY(_peripheralButton.frame)+kItemsSpacing, kButtonSize.width, kButtonSize.height);
    _centralButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_centralButton setFrame:frame];
    [_centralButton setTitle:@"暗号文を受け取る" forState:UIControlStateNormal];
    [_centralButton addTarget:self action:@selector(onCentralButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return _centralButton;
}

- (UIButton *)infoButton {
    if (_infoButton) return _infoButton;
    CGRect frame = CGRectMake(CGRectGetWidth(self.view.frame)-kInfoButtonSize.width-kLayoutSpacing, CGRectGetHeight(self.view.frame)-kInfoButtonSize.height-kLayoutSpacing, kInfoButtonSize.width, kInfoButtonSize.height);
    _infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [_infoButton setFrame:frame];
    [_infoButton addTarget:self action:@selector(onInfoButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return _infoButton;
}

@end
