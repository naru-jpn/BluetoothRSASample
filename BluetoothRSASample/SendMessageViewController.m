//
//  SendMessageViewController.m
//
//  Created by naru on 2015/10/28.
//  Copyright © 2015年 Apple. All rights reserved.
//

#import "SendMessageViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"

static NSInteger modpow(NSInteger base, NSInteger exp, NSInteger modulus);

static CGFloat kTextViewFontSize = 16.0f;
static CGSize kTextViewSize = (CGSize){300.0f, 100.0f};
static NSString * const SampleText = @"sample";

static CGFloat kItemsSpacing = 24.0f;
static CGFloat kFontSize = 15.0f;
static CGSize kSwitchSize = (CGSize){51.0f, 31.0f};

@interface SendMessageViewController () <CBPeripheralManagerDelegate, UITextViewDelegate>
@property (strong, nonatomic) UITextView       *textView;
@property (strong, nonatomic) UITextView       *codedTextView;
@property (strong, nonatomic) UISwitch         *advertisingSwitch;
@property (strong, nonatomic) UILabel *advertisingLabel;
@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@end



#define NOTIFY_MTU      20



@implementation SendMessageViewController



#pragma mark - View Lifecycle



- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:@"暗号文を送る"];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    [self.view addSubview:self.textView];
    [self.view addSubview:self.codedTextView];
    [self.view addSubview:self.advertisingLabel];
    [self.view addSubview:self.advertisingSwitch];
    
    
    
    NSLog(@"ascii %@", [self asciiCodeString]);
    NSLog(@"coded %@", [self codedMessageWithAsciiCodeString:[self asciiCodeString]]);
    
    // Start up the CBPeripheralManager
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 公開鍵が登録されているか確認
    if ([self publicKey1]<=0 || [self publicKey2]<=0) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"公開鍵が見つかりません" message:@"暗号化されたメッセージを送信する為には、公開鍵が必要です。" preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (UITextView *)textView {
    if (_textView) return _textView;
    UIFont *font = [UIFont systemFontOfSize:kTextViewFontSize];
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kTextViewSize.width)/2.0f, 100.0f, kTextViewSize.width, kTextViewSize.height);
    _textView = [[UITextView alloc] initWithFrame:frame];
    [_textView setFont:font];
    [_textView.layer setBorderWidth:0.5f];
    [_textView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [_textView setText:SampleText];
    [_textView setDelegate:self];
    return _textView;
}

- (UITextView *)codedTextView {
    if (_codedTextView) return _codedTextView;
    UIFont *font = [UIFont systemFontOfSize:kTextViewFontSize-2];
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kTextViewSize.width)/2.0f, CGRectGetMaxY(_textView.frame)+kItemsSpacing, kTextViewSize.width, kTextViewSize.height);
    _codedTextView = [[UITextView alloc] initWithFrame:frame];
    [_codedTextView setFont:font];
    [_codedTextView.layer setBorderWidth:0.5f];
    [_codedTextView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [_codedTextView setDelegate:self];
    [_codedTextView setEditable:NO];
    [_codedTextView setText:[self codedMessageWithAsciiCodeString:[self asciiCodeString]]];
    return _codedTextView;
}

- (UILabel *)advertisingLabel {
    if (_advertisingLabel) return _advertisingLabel;
    CGFloat layoutSpacing = (CGRectGetWidth(self.view.frame)-kTextViewSize.width)/2.0f;
    UIFont *font = [UIFont systemFontOfSize:kFontSize];
    CGRect frame = CGRectMake(layoutSpacing, CGRectGetMaxY(_codedTextView.frame)+kItemsSpacing+4.0f, 100.0f, ceil(font.lineHeight));
    _advertisingLabel = [[UILabel alloc] initWithFrame:frame];
    [_advertisingLabel setFont:font];
    [_advertisingLabel setTextColor:[UIColor grayColor]];
    [_advertisingLabel setText:@"Advertising"];
    return _advertisingLabel;
}

- (UISwitch *)advertisingSwitch {
    if (_advertisingSwitch) return _advertisingSwitch;
    CGFloat layoutSpacing = (CGRectGetWidth(self.view.frame)-kTextViewSize.width)/2.0f;
    CGRect frame = CGRectMake(CGRectGetWidth(self.view.frame)-layoutSpacing-kSwitchSize.width, CGRectGetMaxY(_codedTextView.frame)+kItemsSpacing, kSwitchSize.width, kSwitchSize.height);
    _advertisingSwitch = [[UISwitch alloc] initWithFrame:frame];
    [_advertisingSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    return _advertisingSwitch;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [self.peripheralManager stopAdvertising];

    [super viewWillDisappear:animated];
}

#pragma mark - convert

static NSInteger modpow(NSInteger base, NSInteger exp, NSInteger modulus) {
    base %= modulus;
    NSInteger result = 1;
    NSInteger buf = exp;
    while (buf > 0) {
        if (buf & 1) result = (result * base) % modulus;
        base = (base * base) % modulus;
        buf >>= 1;
    }
    NSLog(@"modpow: %ld^%ld ≡ %ld (mod %ld)", (long)base, (long)exp, (long)result, (long)modulus);
    return result;
}

- (NSString *)asciiCodeString {
    NSString *string = _textView.text;
    NSInteger length = string.length;
    NSMutableString *ascii = [NSMutableString string];
    for (NSInteger i=0; i<length; i++) {
        NSInteger code = [string characterAtIndex:i];
        [ascii appendString:[NSString stringWithFormat:@"%ld ", (long)code]];
    }
    return (ascii.length>0) ? [ascii substringToIndex:(ascii.length-1)] : ascii;
}

- (NSInteger)publicKey1 {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:@"public1"] integerValue];
}

- (NSInteger)publicKey2 {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:@"public2"] integerValue];
}

- (NSString *)codedMessageWithAsciiCodeString:(NSString *)string {
    NSArray *components = [string componentsSeparatedByString:@" "];
    NSMutableString *message = [NSMutableString string];
    for (NSString *component in components) {
        NSInteger code = component.integerValue;
        [message appendString:[NSString stringWithFormat:@"%ld ", (long)modpow(code, [self publicKey1], [self publicKey2])]];
    }
    return (message.length>0) ? [message substringToIndex:(message.length-1)] : message;
}

#pragma mark - Peripheral Methods



/** Required protocol method.  A full app should take care of all the possible states,
 *  but we're just waiting for  to know when the CBPeripheralManager is ready
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");
    
    // ... so build our service.
    
    // Start with the CBMutableCharacteristic
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                      properties:CBCharacteristicPropertyNotify
                                                                           value:nil
                                                                     permissions:CBAttributePermissionsReadable];

    // Then the service
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
                                                                        primary:YES];
    
    // Add the characteristic to the service
    transferService.characteristics = @[self.transferCharacteristic];
    
    // And add it to the peripheral manager
    [self.peripheralManager addService:transferService];
}


/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    // Get the data
    self.dataToSend = [[self codedMessageWithAsciiCodeString:[self asciiCodeString]] dataUsingEncoding:NSUTF8StringEncoding];
    
    // Reset the index
    self.sendDataIndex = 0;
    
    // Start sending
    [self sendData];
}


/** Recognise when the central unsubscribes
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
}


/** Sends the next amount of data to the connected central
 */
- (void)sendData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
}


/** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *  This is to ensure that packets will arrive in the order they are sent
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    // Start sending again
    [self sendData];
}



#pragma mark - TextView Methods



/** This is called when a change happens, so we know to stop advertising
 */
- (void)textViewDidChange:(UITextView *)textView
{
    if (_textView.text.length > 0) {
        [_codedTextView setText:[self codedMessageWithAsciiCodeString:[self asciiCodeString]]];
    } else {
        [_codedTextView setText:@""];
    }
    // If we're already advertising, stop
    if (self.advertisingSwitch.on) {
        [self.advertisingSwitch setOn:NO];
        [self.peripheralManager stopAdvertising];
    }
}


/** Adds the 'Done' button to the title bar
 */
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // We need to add this manually so we have a way to dismiss the keyboard
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard)];
    self.navigationItem.rightBarButtonItem = rightButton;
}


/** Finishes the editing */
- (void)dismissKeyboard
{
    [self.textView resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}



#pragma mark - Switch Methods



/** Start advertising
 */
- (IBAction)switchChanged:(id)sender
{
    if (self.advertisingSwitch.on) {
        // All we advertise is our service's UUID
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
    }
    
    else {
        [self.peripheralManager stopAdvertising];
    }
}


@end
