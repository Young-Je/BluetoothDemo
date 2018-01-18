//
//  ViewController.m
//  ble sps
//
//  Created by shenhark on 15/4/8.
//  Copyright (c) 2015年 shenhark. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSString    *recvText;
    unsigned long recvBytes;
    unsigned long sendBytes;
}
@end


@implementation ViewController

@synthesize devName,sendTextView,sendByteLabel,sendByteBtn,asiicHexBtn,cleanSendDataBtn,sendBtn,recvTextView,recvByteLabel,
recvByteBtn,recvAsiicHexBtn,ClearBtn,scanBtn,mBluetoothUtils,scanIndicator;


-(unsigned char)Hex:(unsigned char)value{
    unsigned char tH = value;
    unsigned char vH;
    if (tH >= '0' && tH <= '9') {
        vH = tH - '0';
    }else if (tH >= 'a' && tH <= 'f'){
        vH = tH - 'a' + 10;
    }else {
        vH = tH - 'A' + 10;
    }
    
    return vH;
}

-(unsigned char)getHex:(unsigned char[2])value{
    unsigned char tH = value[0],tL = value[1];
    unsigned char vH,vL;
    if (tH >= '0' && tH <= '9') {
        vH = tH - '0';
    }else if (tH >= 'a' && tH <= 'f'){
        vH = tH - 'a' + 10;
    }else {
        vH = tH - 'A' + 10;
    }
    
    if (tL >= '0' && tL <= '9') {
        vL = tL - '0';
    }else if (tL >= 'a' && tL <= 'f'){
        vL = tL - 'a' + 10;
    }else {
        vL = tL - 'A' + 10;
    }
    
    unsigned char h = vH<<4,l = vL;
    unsigned char rV = h|l;
    return rV;
}

-(NSData *)stringToHexData:(NSString *)string{
    NSMutableData *returnData = [[NSMutableData alloc] init];
    const char *temp = [string UTF8String];
    unsigned long len = strlen(temp);
    for (int i = 0; i < len; i+=2) {
        unsigned char doubleChar[2];
        if (i<len) {
            doubleChar[0] = temp[i];
        }
        if (i+1<len) {
            doubleChar[1] = temp[i+1];
        }
        
        unsigned char temp = [self getHex:doubleChar];
        [returnData appendData:[NSData dataWithBytes:&temp length:1]];
    }
    return [NSData dataWithData:returnData];
}

- (void)initView{
    
    //Title
    UILabel *l1 = [[UILabel alloc]initWithFrame:CGRectMake((self.view.frame.size.width-200)/2,15, 200,40)];
    l1.font = [UIFont fontWithName:nil size:25.0];
    l1.textColor = [UIColor blackColor];
    l1.textAlignment = NSTextAlignmentCenter;
    devName = l1;
    devName.text = @"Device Name";
    [self.view addSubview:devName];
    
    //SendTextView
    float sH = self.view.frame.size.height/3;
    UITextView *t1 = [[UITextView alloc]initWithFrame:CGRectMake(10,60,(self.view.frame.size.width-20),sH)];
    t1.backgroundColor = [UIColor blackColor];
    sendTextView = t1;
    sendTextView.textColor = [UIColor whiteColor];
    sendTextView.font = [UIFont fontWithName:nil size:20.0];
    [self.view addSubview:sendTextView];
    
    //Send Option
    UILabel *l2 = [[UILabel alloc]initWithFrame:CGRectMake(10,sH+60+5,150,40)];
    l2.text = @"sendBytes:";
    l2.font = [UIFont fontWithName:nil size:25];
    l2.textColor = [UIColor blackColor];
    sendByteLabel = l2;
    [self.view addSubview:sendByteLabel];
    
    UIButton *b2 = [[UIButton alloc]initWithFrame:CGRectMake(160,sH+60+5,80,40)];
    [b2 setTitle:@"0" forState:UIControlStateNormal];
    [b2 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
     [b2 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b2 addTarget:self action:@selector(clearSendBytes) forControlEvents:UIControlEventTouchDown];
    sendByteBtn = b2;
    [self.view addSubview:sendByteBtn];
    
    UIButton *b3 = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-250,sH+60+5,60,40)];
    [b3 setTitle:@"Ascii" forState:UIControlStateNormal];
    [b3 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [b3 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b3 addTarget:self action:@selector(SendAsiicHex) forControlEvents:UIControlEventTouchDown];
    asiicHexBtn = b3;
    [self.view addSubview:asiicHexBtn];
    
    UIButton *b8= [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-180,sH+60+5,60,40)];
    [b8 setTitle:@"Clean" forState:UIControlStateNormal];
    [b8 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [b8 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b8 addTarget:self action:@selector(CleanSendData) forControlEvents:UIControlEventTouchDown];
    cleanSendDataBtn = b8;
    [self.view addSubview:cleanSendDataBtn];
    
    UIButton *b4 = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-80,sH+60+5,70,40)];
    [b4 setTitle:@"Send" forState:UIControlStateNormal];
    [b4 setBackgroundColor:[UIColor blackColor]];
    [b4 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [b4 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b4 setTitleShadowColor:[UIColor yellowColor] forState:UIControlStateHighlighted];
    [b4 addTarget:self action:@selector(SendData) forControlEvents:UIControlEventTouchDown];
    sendBtn = b4;
    [self.view addSubview:sendBtn];
    
    //RecvTextRecv
    float rH = self.view.frame.size.height*2/3-250;
    float y = self.view.frame.size.height/3+120;
    UITextView *t2 = [[UITextView alloc]initWithFrame:CGRectMake(10,y,(self.view.frame.size.width-20),rH)];
    t2.backgroundColor = [UIColor blackColor];
    recvTextView = t2;
    recvTextView.textColor = [UIColor whiteColor];
    recvTextView.font = [UIFont fontWithName:nil size:20.0];
    recvTextView.editable = NO;
    recvTextView.scrollEnabled = YES;
    [self.view  addSubview:recvTextView];
    
    //Recv Option
    UILabel *l3 = [[UILabel alloc]initWithFrame:CGRectMake(10,y+rH+5,150,40)];
    l3.text = @"recvBytes:";
    l3.font = [UIFont fontWithName:nil size:25];
    l3.textColor = [UIColor blackColor];
    recvByteLabel = l3;
    [self.view addSubview:recvByteLabel];
    
    UIButton *b5 = [[UIButton alloc]initWithFrame:CGRectMake(160,y+rH+5,80,40)];
    [b5 setTitle:@"0" forState:UIControlStateNormal];
    [b5 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [b5 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b5 addTarget:self action:@selector(clearRecvBytes) forControlEvents:UIControlEventTouchDown];
    recvByteBtn = b5;
    [self.view addSubview:recvByteBtn];
    
    UIButton *b6 = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-250,y+rH+5,60,40)];
    [b6 setTitle:@"Ascii" forState:UIControlStateNormal];
    [b6 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b6 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [b6 addTarget:self action:@selector(recvSendAsiicHex) forControlEvents:UIControlEventTouchDown];
    recvAsiicHexBtn = b6;
    [self.view addSubview:recvAsiicHexBtn];
    
    UIButton *b7 = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-80,y+rH+5,70,40)];
    [b7 setTitle:@"Clean" forState:UIControlStateNormal];
    [b7 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [b7 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [b7 addTarget:self action:@selector(clearData) forControlEvents:UIControlEventTouchDown];
    ClearBtn = b7;
    [self.view addSubview:ClearBtn];

    
    
    UIButton *b1 = [[UIButton alloc]initWithFrame:CGRectMake(10,self.view.frame.size.height-80,(self.view.frame.size.width-20), 70)];
    b1.backgroundColor = [UIColor blackColor];
    [b1 setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [b1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [b1 setTitle:@"Scan BLE Device" forState:UIControlStateNormal];
    [b1 addTarget:self action:@selector(scanDev) forControlEvents:UIControlEventTouchDown];
    scanBtn = b1;
    [self.view addSubview:scanBtn];
    
    scanIndicator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(self.view.frame.size.width-80, 10,30,30)];
    scanIndicator.color = [UIColor blueColor];
    [scanBtn addSubview:scanIndicator];
}

- (void)clearSendBytes{
    [sendByteBtn setTitle:@"0" forState:UIControlStateNormal];
}

- (void)SendAsiicHex{
    NSString *data = [asiicHexBtn titleForState:UIControlStateNormal];
    
    if ([data isEqualToString:@"Ascii"])
    {
        [asiicHexBtn setTitle:@"Hex" forState:UIControlStateNormal];
    }
    else
    {
        [asiicHexBtn setTitle:@"Ascii" forState:UIControlStateNormal];
    }
}

- (void)CleanSendData{
    sendTextView.text=@"";
    sendBytes = 0;
}


- (void)clearRecvBytes{
    [recvByteBtn setTitle:@"0" forState:UIControlStateNormal];
    recvBytes = 0;
}

- (void)recvSendAsiicHex{
    NSString *data = [recvAsiicHexBtn titleForState:UIControlStateNormal];
    
    if ([data isEqualToString:@"Ascii"])
    {
        [recvAsiicHexBtn setTitle:@"Hex" forState:UIControlStateNormal];
    }
    else
    {
        [recvAsiicHexBtn setTitle:@"Ascii" forState:UIControlStateNormal];
    }
}

- (void) clearData{
    recvTextView.text=@"";
}

- (void)scanDev{
    [mBluetoothUtils beginScan:3 withServiceUUID:@[[CBUUID UUIDWithString:@"FEE0"]]];
    // [mBluetoothUtils beginScan:10 withServiceUUID:nil];
    [scanIndicator startAnimating];
}

- (void)SendData{
    
    NSString *str = [[NSString alloc]initWithFormat:@"%@",sendTextView.text];
    
    
    if ([asiicHexBtn.titleLabel.text isEqualToString:@"Ascii"])
    {
        sendBytes += str.length;
         NSData *data = [str dataUsingEncoding: NSUTF8StringEncoding];
        [mBluetoothUtils writeValue:0xfee0 characteristicUUID:0xfee1 p:mBluetoothUtils.activePeripheral data:data];
    }
    else
    {
        sendBytes += str.length/2;
        NSData *data = [[NSData alloc]initWithData:[self stringToHexData:str]];
        [mBluetoothUtils writeValue:0xfee0 characteristicUUID:0xfee1 p:mBluetoothUtils.activePeripheral data:data];
    }
    
     [sendByteBtn setTitle:[[NSString alloc]initWithFormat:@"%ld",sendBytes] forState:UIControlStateNormal];
}


- (void)viewDidLoad {

    [super viewDidLoad];

    [self initView];
    
    mBluetoothUtils = [[BluetoothUtils alloc]init];
    
    [mBluetoothUtils initBLE];
    
    mBluetoothUtils.delegate = self;
    
    recvText = [[NSString alloc]init];
    
    recvBytes = 0;
    sendBytes = 0;
}

#pragma BluetoothUtils Delegate
- (void)ScanCompleteNotify{
    [scanIndicator stopAnimating];
    
    UIActionSheet *portsList = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancle" destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    for (int i=0;i<mBluetoothUtils.peripherals.count;i++)
    {
        CBPeripheral *peripheral = mBluetoothUtils.peripherals[i];
        int rssi = [mBluetoothUtils.devRssi[i] intValue];
        NSString *string = [NSString stringWithFormat:@"%@,RSSI=%d",peripheral.name,rssi];
        [portsList addButtonWithTitle: string];
    }
    [portsList showInView:self.view];

}

- (void)CharacterDiscCompleteNotify{
    [mBluetoothUtils notification:0xfee0 characteristicUUID:0xfee1 p:mBluetoothUtils.activePeripheral on:YES];
}

- (void)DataComeNotify:(NSUInteger)len{
    recvText = recvTextView.text;
    
    if ([recvAsiicHexBtn.titleLabel.text isEqualToString:@"Ascii"])
    {
        NSString *str = [[NSString alloc] initWithData:[mBluetoothUtils readSppData:len ] encoding:NSASCIIStringEncoding];
        str = [str stringByReplacingOccurrencesOfString:@"<" withString:@""];
        str = [str stringByReplacingOccurrencesOfString:@">" withString:@""];
        
        if (str==nil)
        {
            return ;
        }
        recvText = [recvText stringByAppendingString:str];
        recvTextView.text  = recvText;
    
    }
    else
    {
        NSData *data = [[NSData alloc]initWithData:[mBluetoothUtils readSppData:len]];
        NSString *string = [[NSString alloc]initWithFormat:@"%@",data.description];
        string = [string stringByReplacingOccurrencesOfString:@"<" withString:@""];
        string = [string stringByReplacingOccurrencesOfString:@">" withString:@""];
        if (string==nil)
        {
            return ;
        }
        recvText = [recvText stringByAppendingString:string];
        recvTextView.text  = recvText;
    }
    [recvTextView scrollRangeToVisible:NSMakeRange(recvTextView.text.length, 0)];
    
    recvBytes+=len;
    [recvByteBtn setTitle:[[NSString alloc]initWithFormat:@"%ld",recvBytes] forState:UIControlStateNormal];
    //[recvTextView setScrollEnabled:NO];
    //[recvTextView setScrollEnabled:YES];
}


- (void)DisconnectNotify{

}
#pragma ActionSheet Delegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex!=0) {
        CBPeripheral *p = mBluetoothUtils.peripherals[buttonIndex-1];
        devName.text = p.name;
        [mBluetoothUtils connectPeripheral:p];
    }
}

@end
