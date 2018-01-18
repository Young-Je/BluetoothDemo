//
//  BluetoothUtils.m
//  ble sps
//
//  Created by shenhark on 15/4/9.
//  Copyright (c) 2015年 shenhark. All rights reserved.
//

#import "BluetoothUtils.h"

#define SPS_SERVICE_UUID   0xfee0
#define SPS_CHAR_UUID      0xfee1

@implementation BluetoothUtils

@synthesize CM,scanTimer,peripherals,devRssi, activePeripheral,readBuffer ;
/*!
 *  @method initBLE:
 *  初始化蓝牙Center角色
 *
 */
- (int)initBLE{
    dispatch_queue_t centralQueue = dispatch_queue_create("com.smartwebee.sps", DISPATCH_QUEUE_SERIAL);
    
    self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue];
    
    readBuffer = [[NSMutableData alloc] init];
    
    return 0;
}

/*!
 *  @method centralManagerStateToString:
 *
 *  @param state State to print info of
 *
 *  @discussion centralManagerStateToString prints information text about a given CBCentralManager state
 *
 */
- (const char *) centralManagerStateToString: (int)state{
    switch(state) {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    return "Unknown state";
}

/*!
 *  @method beginScan:
 *
 *  @param timeout timeout in seconds to search for BLE peripherals
 *
 *  @return 0 (Success), -1 (Fault)
 *
 *  @discussion 开始扫描设备
 *
 */
- (int) beginScan:(int) timeout withServiceUUID:(NSArray *)uuids{
    NSLog(@"Start scan ble peripherals...\n");
    if (self.CM.state  != CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth not correctly initialized !\r\n");
        NSLog(@"State = %s\r\n",[self centralManagerStateToString:self.CM.state]);
        return -1;
    }
    
    self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    [self.peripherals removeAllObjects];
    self.peripherals = nil;//置空
    [self.devRssi removeAllObjects];
    self.devRssi = nil;
    [self.CM scanForPeripheralsWithServices:uuids options:0]; // Start scanning
    return 0; // Started scanning OK !
}



-(void)stopScan{
    if(self.scanTimer){
        [scanTimer invalidate];
        scanTimer = nil;
    }
    [self.CM stopScan];
}
/*!
 *  @method scanTimer:
 *
 *  @param timer Backpointer to timer
 *
 *  @discussion scanTimer is called when findBLEPeripherals has timed out, it stops the CentralManager from scanning further and prints out information about known peripherals
 *
 */
- (void) scanTimer:(NSTimer *)timer {
    [self.CM stopScan];
    
    if ([self.delegate respondsToSelector:@selector(ScanCompleteNotify)])
    {
        [self.delegate ScanCompleteNotify];
    }
}

-(int) samePeripheral:(CBPeripheral *)p1 p2:(CBPeripheral *)p2{
    if (p1 == nil || p2 == nil) {
        NSLog(@"p is nil\n");
        return -1;
    }
    if (p1 == p2) {
        return 1;
    }else{
        return 0;
    }
}


/*!
 *  @method notification:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for enabling and disabling notification services. It converts integers
 *  into CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the notfication is set.
 *
 */
-(void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUID:su p:p];
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    
    if (!service) {
        NSLog(@"Could not find service with UUID %s on %@\r\n",[self CBUUIDToString:su],p.name);
        return;
    }
    
    if (!characteristic) {
        NSLog(@"Could not find characteristic with UUID %s on service with UUID %s on %@\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],p.name);
        return;
    }
    NSLog(@"setNotifyValue characteristic!\r\n");
    
    [p setNotifyValue:on forCharacteristic:characteristic];
}


/*!
 *  @method writeValue:
 *
 *  @param serviceUUID Service UUID to write to (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to write to (e.g. 0x2401)
 *  @param data Data to write to peripheral
 *  @param p CBPeripheral to write to
 *
 *  @discussion Main routine for writeValue request, writes without feedback. It converts integer into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, value is written. If not nothing is done.
 *
 */
-(void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUID:su p:p];
    
    if (!service) {
        NSLog(@"Could not find service UUID %sr\n",[self CBUUIDToString:su]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];//[[CBCharacteristic alloc] init];//
    //[characteristic setUUID:cu];
    NSLog(@"Value Write!\n\n");
    if (!characteristic) {
        NSLog(@"Could not find characteristic with UUID %s on service with UUID %s \r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su]);
        return;
    }
    
    if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }else{
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}

/*!
 *  @method readValue:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for read value request. It converts integers into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the read value is started. When value is read the didUpdateValueForCharacteristic
 *  routine is called.
 *
 *  @see didUpdateValueForCharacteristic
 */

-(void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        NSLog(@"Could not find service with UUID %s on %@\r\n",[self CBUUIDToString:su],p.name);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        NSLog(@"Could not find characteristic with UUID %s on service with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su]);
        return;
    }
    [p readValueForCharacteristic:characteristic];
}

/*
 readDataFromPort:withLength:
 */
-(NSData *)readSppData:(NSUInteger)length{
        if (readBuffer)
        {
            NSUInteger realLen = (length<=readBuffer.length)?length:readBuffer.length;
            NSData *rData = [readBuffer subdataWithRange:NSMakeRange(0, realLen)];
            if (realLen == readBuffer.length)
            {
                readBuffer = [[NSMutableData alloc] init];
            }
            else
            {
                readBuffer = [NSMutableData dataWithData:[readBuffer subdataWithRange:NSMakeRange(realLen, readBuffer.length-realLen)]];
            }
            return rData;
        }
        else
        {
            return nil;
        }
}

/*!
 *  @method connectPeripheral:
 *
 *  @param p Peripheral to connect to
 *
 *  @discussion connectPeripheral connects to a given peripheral and sets the activePeripheral property of TIBLECBKeyfob.
 *
 */
- (void) connectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connecting to %@\r\n",peripheral.name);
    activePeripheral = peripheral;
    activePeripheral.delegate = self;
    [CM connectPeripheral:activePeripheral options:nil];
}

//Central Delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"Status of CoreBluetooth central manager changed %ld (%s)\r\n",central.state,[self centralManagerStateToString:central.state]);
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"find : %s\n",[advertisementData.description UTF8String]);
        NSLog(@"ManuData:%@",[advertisementData valueForKey:@"kCBAdvDataManufacturerData"]);
        
        if (!self.peripherals)
        {
            self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
            self.devRssi = [[NSMutableArray alloc]initWithObjects:RSSI, nil];
            if([self.delegate respondsToSelector:@selector(ScanNewPeripheralDevice:WithAdvertisementData:)])
            {
                [self.delegate ScanNewPeripheralDevice:peripheral WithAdvertisementData:advertisementData];
            }
        }
        else
        {
            NSLog(@"exist peripherals count is %lu",(unsigned long)self.peripherals.count);
            for(int i = 0; i < self.peripherals.count; i++)
            {
                CBPeripheral *p = [self.peripherals objectAtIndex:i];
                if ([self samePeripheral:p p2:peripheral])
                {
                    [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
                    [self.devRssi replaceObjectAtIndex:i withObject:RSSI];
                    NSLog(@"Duplicate UUID found updating ...\r\n");
                    return;
                }
            }
            [self.peripherals addObject:peripheral];//添加
            [self.devRssi addObject:RSSI];
            if([self.delegate respondsToSelector:@selector(ScanNewPeripheralDevice:WithAdvertisementData:)])
            {
                [self.delegate ScanNewPeripheralDevice:peripheral WithAdvertisementData:advertisementData];
            }
            NSLog(@"New UUID, adding\r\n");
        }
        NSLog(@"didDiscoverPeripheral\r\n");
        
    });
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Connection to  : %@ successfull\r\n",peripheral.name);
        self.activePeripheral = peripheral;
        
        [self.activePeripheral discoverServices:nil];
        NSLog(@"start discover service...");
    });
}


/*!
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16
 *
 *  @return Byteswapped UInt16
 */

-(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

/*
 *  @method compareCBUUID
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compareCBUUID compares two CBUUID's to each other and returns 1 if they are equal and 0 if they are not
 *
 */

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}

/*
 *  @method findServiceFromUUID:
 *
 *  @param UUID CBUUID to find in service list
 *  @param p Peripheral to find service on
 *
 *  @return pointer to CBService if found, nil if not
 *
 *  @discussion findServiceFromUUID searches through the services list of a peripheral to find a
 *  service with a specific UUID
 *
 */
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p {
    for(int i = 0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}

/*
 *  @method CBUUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion CBUUIDToString converts the data of a CBUUID class to a character pointer for easy printout using printf()
 *
 */
-(const char *) CBUUIDToString:(CBUUID *) UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}


/*
 *  @method UUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion UUIDToString converts the data of a CFUUIDRef class to a character pointer for easy printout using printf()
 *
 */
-(const char *) UUIDToString:(CFUUIDRef)UUID {
    if (!UUID) return "NULL";
    CFStringRef s = CFUUIDCreateString(NULL, UUID);
    return CFStringGetCStringPtr(s, 0);
    
}

/*
 *  @method CBUUIDToInt
 *
 *  @param UUID1 UUID 1 to convert
 *
 *  @returns UInt16 representation of the CBUUID
 *
 *  @discussion CBUUIDToInt converts a CBUUID to a Uint16 representation of the UUID
 *
 */
-(UInt16) CBUUIDToInt:(CBUUID *) UUID {
    unsigned char b1[16];
    [UUID.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}
/*
 *  @method findCharacteristicFromUUID:
 *
 *  @param UUID CBUUID to find in Characteristic list of service
 *  @param service Pointer to CBService to search for charateristics on
 *
 *  @return pointer to CBCharacteristic if found, nil if not
 *
 *  @discussion findCharacteristicFromUUID searches through the characteristic list of a given service
 *  to find a characteristic with a specific UUID
 *
 */
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"Disconnect complete!\r\n");
        self.activePeripheral = nil;
        if ([self.delegate respondsToSelector:@selector(DisconnectNotify)])
        {
            [self.delegate DisconnectNotify];
        }
    });
    
}

//----------------------------------------------------------------------------------------------------
//
//
//
//
//
//CBPeripheralDelegate protocol methods beneeth here
//----------------------------------------------------------------------------------------------------

/*
 *  @method getAllCharacteristics
 *
 *  @param p Peripheral to scan
 *
 *
 *  @discussion getAllCharacteristics starts a characteristics discovery on a peripheral
 *  pointed to by p
 *
 */
-(void) getAllCharacteristics:(CBPeripheral *)p{
    
    for (int i=0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        NSLog(@"Fetching characteristics for service with UUID : %s\r\n",[self CBUUIDToString:s.UUID]);
        NSLog(@"UUID:%@",s.UUID.data.description);
        
        /**可以再次判断是否有目标的服务UUID
         if ([s.UUID.data.description isEqualToString:@"<ffa0>"])
         {
         beaconFlg = true;
         NSLog(@"Get <ffa0>");
         }
         */
        
        [p discoverCharacteristics:nil forService:s];
    }
}
/*
 *  @method didDiscoverServices
 *
 *  @param peripheral Pheripheral that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverServices is called when CoreBluetooth has discovered services on a
 *  peripheral after the discoverServices routine has been called on the peripheral
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!error) {
            NSLog(@"Services of peripheral found\r\n");
            NSLog(@"Count of services is : %lu\r\n",(unsigned long)peripheral.services.count);
            [self getAllCharacteristics:peripheral];
            if ([self.delegate respondsToSelector:@selector(ServiceDiscCompleteNotify)])
            {
                [self.delegate ServiceDiscCompleteNotify];
            }
        }
        else {
            NSLog(@"Service discovery was unsuccessfull !\r\n");
        }
        
    });
    
    
}

/*
 *  @method didDiscoverCharacteristicsForService
 *
 *  @param peripheral Pheripheral that got updated
 *  @param service Service that characteristics where found on
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverCharacteristicsForService is called when CoreBluetooth has discovered
 *  characteristics on a service, on a peripheral after the discoverCharacteristics routine has been called on the service
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!error) {
            NSLog(@"Characteristics of service with UUID : %s found\r\n",[self CBUUIDToString:service.UUID]);
            for(int i=0; i < service.characteristics.count; i++) {
                CBCharacteristic *c = [service.characteristics objectAtIndex:i];
                NSLog(@"Found characteristic %s property 0x%2lx\r\n",[ self CBUUIDToString:c.UUID],c.properties);
                CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
                if([self compareCBUUID:service.UUID UUID2:s.UUID]) {
                    NSLog(@"Finished discovering characteristics\r\n");
                    if (i == service.characteristics.count - 1) {
                        if ([self.delegate respondsToSelector:@selector(CharacterDiscCompleteNotify)]) {
                            [self.delegate CharacterDiscCompleteNotify];
                        }
                    }
                }
            }
        }
        else {
            NSLog(@"Characteristic discorvery unsuccessfull !\r\n");
        }
        
    });
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error {
}




/*
 *  @method didUpdateNotificationStateForCharacteristic
 *
 *  @param peripheral Pheripheral that got updated
 *  @param characteristic Characteristic that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didUpdateNotificationStateForCharacteristic is called when CoreBluetooth has updated a
 *  notification state for a characteristic
 *
 */
-(BOOL) filterOfCharacUUID:(UInt16) uuid {
    if (uuid == 0x2A18 || uuid == 0x2A34 || uuid == 0x2A52) {
        return  YES;
    }
    return NO;
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!error) {
            NSLog(@"Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral \r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID]);
            
        }
        else {
            NSLog(@"Error in setting notification state for characteristic with UUID %s on service with  UUID %s on peripheral\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID]);
            NSLog(@"Error code was %s\r\n",[[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
            
        }
    });
    
    
}

/*
 *  @method didUpdateValueForCharacteristic
 *
 *  @param peripheral Pheripheral that got updated
 *  @param characteristic Characteristic that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didUpdateValueForCharacteristic is called when CoreBluetooth has updated a
 *  characteristic for a peripheral. All reads and notifications come here to be processed.
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UInt16 characteristicUUID = [self CBUUIDToInt:characteristic.UUID];
        UInt16 serviceUUID = [self CBUUIDToInt:characteristic.service.UUID];
        
        //NSLog(@"=>update Vaue for characteristicUUID:0x%2x\n",characteristicUUID);
        //NSLog(@"data length is : %ld\n",characteristic.value.length);
       // NSLog(@"data : %s\n",[characteristic.value.description UTF8String]);
        if (!error) {
            switch (serviceUUID) {
                case SPS_SERVICE_UUID:
                {
                    switch (characteristicUUID)
                    {
                        case SPS_CHAR_UUID:
                            [readBuffer appendData:characteristic.value];
                            if ([self.delegate respondsToSelector:@selector(DataComeNotify:)])
                            {
                                [self.delegate DataComeNotify:characteristic.value.length];
                            }
                            break;
                            
                        default:
                            break;
                    }
                    
                }
                default:
                    break;
            }
        }
        
        
    });
    
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    
}






@end
