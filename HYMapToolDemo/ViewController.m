//
//  ViewController.m
//  HYMapToolDemo
//
//  Created by MrZhangKe on 16/3/25.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import "ViewController.h"
#import "HYMapViewController.h"


@interface ViewController ()@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
}


- (IBAction)showMap:(UIButton *)sender {
    HYMapViewController *mapVC = [[HYMapViewController alloc] init];
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mapVC];
    [self presentViewController:mapVC animated:YES completion:nil];
}


@end
