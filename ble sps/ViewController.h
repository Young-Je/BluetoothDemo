//
//  ViewController.h
//  ble sps
//
//  Created by shenhark on 15/4/8.
//  Copyright (c) 2015年 shenhark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BluetoothUtils.h"

@interface ViewController : UIViewController<BluetoothUtilsDelegate,UIActionSheetDelegate>


@property (weak,nonatomic)UILabel *devName;

@property(weak,nonatomic)UITextView *sendTextView;
@property(weak,nonatomic)UILabel *sendByteLabel;
@property(weak,nonatomic)UIButton *sendByteBtn;
@property(weak,nonatomic)UIButton *asiicHexBtn;
@property(weak,nonatomic)UIButton *cleanSendDataBtn;
@property(weak,nonatomic)UIButton *sendBtn;


@property(weak,nonatomic)UITextView *recvTextView;
@property(weak,nonatomic)UILabel *recvByteLabel;
@property(weak,nonatomic)UIButton *recvByteBtn;
@property(weak,nonatomic)UIButton *recvAsiicHexBtn;
@property(weak,nonatomic)UIButton *ClearBtn;

@property(weak,nonatomic)UIButton* scanBtn;
@property(strong,nonatomic)UIActivityIndicatorView *scanIndicator;

@property(strong,nonatomic)BluetoothUtils *mBluetoothUtils;
@end

