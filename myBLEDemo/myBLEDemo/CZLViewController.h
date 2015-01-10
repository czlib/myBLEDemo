//
//  CZLViewController.h
//  myBLEDemo
//
//  Created by zl.c on 15-1-9.
//  Copyright (c) 2015年 czl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CZLViewController : UIViewController
- (IBAction)onSearch:(UIButton *)sender;
- (IBAction)onDisconnect:(UIButton *)sender;
- (IBAction)onSendData:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UITableView *myTable;
@property (weak, nonatomic) IBOutlet UITextView *myTextView;

@property (weak, nonatomic) IBOutlet UITextField *textFieldInstro;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;

@end
