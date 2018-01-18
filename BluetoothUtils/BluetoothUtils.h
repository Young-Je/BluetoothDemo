//
//  BluetoothUtils.h
//  ble sps
//
//  Created by shenhark on 15/4/9.
//  Copyright (c) 2015年 shenhark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>

@protocol BluetoothUtilsDelegate <NSObject>
@optional
-(void) ScanNewPeripheralDevice:(CBPeripheral *)peripheral WithAdvertisementData:(NSDictionary*)advertiseData;
-(void) ScanCompleteNotify;
-(void) ServiceDiscCompleteNotify;
-(void) CharacterDiscCompleteNotify;
-(void) DataComeNotify:(NSUInteger)len;
-(void) DisconnectNotify;

-(void)rssiUpdate:(NSNumber *)rssi withPeripheral:(CBPeripheral *)p;
@end

@interface BluetoothUtils : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate>{

}

@property (nonatomic,assign) id <BluetoothUtilsDelegate> delegate;
@property (strong, nonatomic)  NSMutableArray *peripherals;
@property (strong, nonatomic) NSMutableArray *devRssi;
@property (strong, nonatomic) CBCentralManager *CM;
@property (strong, nonatomic) NSTimer *scanTimer;
@property (strong, nonatomic) CBPeripheral *activePeripheral;
@property (strong, nonatomic) NSMutableData *readBuffer;

//For Class Use
-(void) getAllCharacteristics:(CBPeripheral *)p;
- (const char *)centralManagerStateToString:(int)state;
-(CBService *)findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p;
-(UInt16)swap:(UInt16)s ;
-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 ;
-(const char *)UUIDToString:(CFUUIDRef)UUID ;
-(const char *)CBUUIDToString:(CBUUID *) UUID ;
-(UInt16) CBUUIDToInt:(CBUUID *) UUID ;
-(CBCharacteristic *)findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service ;


//For User Use
- (int)initBLE;
- (int)beginScan:(int) timeout withServiceUUID:(NSArray *)uuids;
- (void)stopScan;
- (void)connectPeripheral:(CBPeripheral *)peripheral;
- (void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on ;
- (void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;
- (void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p ;
-(NSData *)readSppData:(NSUInteger)length;

@end
