//
//  ReceiveMessageViewController.m
//
//  Created by naru on 2015/10/28.
//  Copyright © 2015年 Apple. All rights reserved.
//

#import "ReceiveMessageViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import "TransferService.h"

static NSInteger modpow(NSInteger base, NSInteger exp, NSInteger modulus);

static CGFloat kItemsSpacing = 24.0f;
static CGFloat kTextViewFontSize = 16.0f;
static CGSize kTextViewSize = (CGSize){300.0f, 100.0f};
static UIEdgeInsets kTextViewInsets = (UIEdgeInsets){8.0f, 8.0f, 8.0f, 8.0f};

static CGSize kButtonSize = (CGSize){200.0f, 44.0f};

@interface ReceiveMessageViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) UITextView   *codedTextView;
@property (strong, nonatomic) UIButton *decryptionButton;
@property (strong, nonatomic) UITextView   *messageTextView;
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;

@end



@implementation ReceiveMessageViewController



#pragma mark - View Lifecycle



- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:@"暗号文を受け取る"];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    [self.view addSubview:self.codedTextView];
    [self.view addSubview:self.decryptionButton];
    [self.view addSubview:self.messageTextView];
        
    // Start up the CBCentralManager
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // And somewhere to store the incoming data
    _data = [[NSMutableData alloc] init];
}

- (UITextView *)codedTextView {
    if (_codedTextView) return _codedTextView;
    UIFont *font = [UIFont systemFontOfSize:kTextViewFontSize-2.0f];
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kTextViewSize.width)/2.0f, 100.0f, kTextViewSize.width, kTextViewSize.height);
    _codedTextView = [[UITextView alloc] initWithFrame:frame];
    [_codedTextView setFont:font];
    [_codedTextView setContentInset:kTextViewInsets];
    [_codedTextView.layer setBorderWidth:0.5f];
    [_codedTextView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [_codedTextView setEditable:NO];
    return _codedTextView;
}

- (UIButton *)decryptionButton {
    if (_decryptionButton) return _decryptionButton;
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kButtonSize.width)/2.0f, CGRectGetMaxY(_codedTextView.frame)+kItemsSpacing, kButtonSize.width, kButtonSize.height);
    _decryptionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_decryptionButton setFrame:frame];
    [_decryptionButton setTitle:@"復号化" forState:UIControlStateNormal];
    [_decryptionButton addTarget:self action:@selector(onDecryptionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return _decryptionButton;
}

- (UITextView *)messageTextView {
    if (_messageTextView) return _messageTextView;
    UIFont *font = [UIFont systemFontOfSize:kTextViewFontSize-2.0f];
    CGRect frame = CGRectMake((CGRectGetWidth(self.view.frame)-kTextViewSize.width)/2.0f, CGRectGetMaxY(_decryptionButton.frame)+kItemsSpacing, kTextViewSize.width, kTextViewSize.height);
    _messageTextView = [[UITextView alloc] initWithFrame:frame];
    [_messageTextView setFont:font];
    [_messageTextView setContentInset:kTextViewInsets];
    [_messageTextView.layer setBorderWidth:0.5f];
    [_messageTextView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [_messageTextView setEditable:NO];
    return _messageTextView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 鍵が登録されているかどうか確認
    if ([self privateKey]<=0 || [self publicKey2]<=0) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"公開鍵もしくは秘密鍵が見つかりません" message:@"暗号化されたメッセージを複合する為には、鍵情報の登録が必要です。" preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
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

- (NSString *)decodedMessage {
    NSString *string = _codedTextView.text;
    NSArray *components = [string componentsSeparatedByString:@" "];
    NSMutableString *message = [NSMutableString string];
    for (NSString *component in components) {
        NSInteger code = component.integerValue;
        code = modpow(code, [self privateKey], [self publicKey2]);
        NSString *character = [NSString stringWithFormat:@"%c", (int)code];
        [message appendString:character];
    }
    return message;
}

- (NSInteger)privateKey {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:@"secret"] integerValue];
}

- (NSInteger)publicKey2 {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:@"public2"] integerValue];
}

#pragma mark - action

- (void)onDecryptionButtonClicked:(id)sedner {
    if (_codedTextView.text.length==0) {
        // メッセージを受け取っていないと復号化できない
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"復号化する対象が見つかりません" message:@"暗号化されたメッセージを受信してください。" preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
        return;
    }
    [_messageTextView setText:[self decodedMessage]];
}

#pragma mark - Central Methods



/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        // In a real app, you'd deal with all the states correctly
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...

    // ... so start scanning
    [self scan];
    
}


/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    NSLog(@"Scanning started");
}


/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is, 
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        return;
    }
        
    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    if (RSSI.integerValue < -35) {
        return;
    }
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral) {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    [self.data setLength:0];

    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}


/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
     
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}


/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"]) {
        
        // We have, so show the data, 
        [self.codedTextView setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
        // Cancel our subscription to the characteristic
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        // and disconnect from the peripehral
        [self.centralManager cancelPeripheralConnection:peripheral];
    }

    // Otherwise, just add the data on to what we already have
    [self.data appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self scan];
}


/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!(self.discoveredPeripheral.state==CBPeripheralStateConnected)) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}


@end
