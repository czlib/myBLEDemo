//
//  CZLViewController.m
//  myBLEDemo
//
//  Created by zl.c on 15-1-9.
//  Copyright (c) 2015年 czl. All rights reserved.
//

#import "CZLViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define NOTHING -1
@interface CZLViewController () <UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,CBCentralManagerDelegate,CBPeripheralDelegate>
/// 设备数组
@property (nonatomic,strong) NSMutableArray *deviceArr;
/// 中央设备管理
@property (nonatomic,strong) CBCentralManager *central;
/// 周边设备
@property (nonatomic,strong) CBPeripheral *peripheral;
/// 断开哪个设备
@property (nonatomic) NSInteger deviceIndex;
@end

@implementation CZLViewController


#pragma mark --view lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.deviceArr = [NSMutableArray array];
    self.deviceIndex = NOTHING;
    self.central = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    // Do any additional setup after loading the view from its nib.
    [self.textFieldInstro setValue:[UIColor whiteColor] forKeyPath:@"_placeholderLabel.textColor"];
    self.myTable.tableFooterView = [UIView new];
    self.myTextView.text = @"";
    
    self.labelStatus.adjustsFontSizeToFitWidth = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClear)];
    self.labelStatus.userInteractionEnabled = YES;
    [self.labelStatus addGestureRecognizer:tap];
}

- (void)onClear
{
    [self.deviceArr removeAllObjects];
    self.deviceIndex = NOTHING;
    self.labelStatus.text = @"";
    [self.myTable reloadData];
}


#pragma mark --tableview delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.deviceArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellid = @"cellid";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellid];
    }
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = [self.deviceArr[indexPath.row] description];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.deviceIndex = indexPath.row;
    self.peripheral = self.deviceArr[indexPath.row];
    [self.central connectPeripheral:self.deviceArr[indexPath.row] options:nil];
}

#pragma mark --textview delegate


#pragma mark --centralmanager delegate
// 监测蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            self.labelStatus.text = @"蓝牙设备已关闭";
            break;
        case CBCentralManagerStateResetting:
            self.labelStatus.text = @"蓝牙设备被重置";
            break;
        case CBCentralManagerStatePoweredOn:
            self.labelStatus.text = @"蓝牙设备已打开";
            break;
        case CBCentralManagerStateUnauthorized:
            self.labelStatus.text = @"未被授权使用蓝牙";
            break;
        case CBCentralManagerStateUnknown:
            self.labelStatus.text = @"未知的蓝牙状态";
            break;
        case CBCentralManagerStateUnsupported:
            self.labelStatus.text = @"设备不支持蓝牙";
            break;
        default:
            break;
    }
}

// 扫描设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    self.peripheral = peripheral;
    [self.central stopScan];
    if (![self.deviceArr containsObject:peripheral]) {
        [self.deviceArr addObject:peripheral];
        [self.myTable reloadData];
    }
    self.labelStatus.text = [NSString stringWithFormat:@"发现蓝牙设备%d个",self.deviceArr.count];
}

// 连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    self.labelStatus.text = [NSString stringWithFormat:@"已连接设备:%@,RSSI:%d",peripheral.name,peripheral.RSSI.intValue];
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
//    self.labelStatus.text = @"开始扫描服务...";
}

// 连接外设失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.labelStatus.text = error.description;
}

-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    //NSLog(@"%s,%@",__PRETTY_FUNCTION__,peripheral);
    int rssi = abs([peripheral.RSSI intValue]);
    CGFloat ci = (rssi - 49) / (10 * 4.);
    NSString *length = [NSString stringWithFormat:@"发现BLT4.0热点:%@,距离:%.1fm",self.peripheral,pow(10,ci)];
    NSLog(@"距离：%@",length);
}

#pragma mark --peripheral delegate


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark --button methods
- (IBAction)onSearch:(UIButton *)sender {
    self.labelStatus.text = @"正在扫描设备...";
    [self.central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.central stopScan];
        self.labelStatus.text = @"扫描超时，停止扫描!";
    });
}

- (IBAction)onDisconnect:(UIButton *)sender {
    if (self.deviceIndex != NOTHING) {
        [self.central cancelPeripheralConnection:self.deviceArr[self.deviceIndex]];
        self.labelStatus.text = @"设备已断开";
    }
    else
    {
        self.labelStatus.text = @"没有需要断开的设备";
    }
}

- (IBAction)onSendData:(UIButton *)sender {
}
@end
