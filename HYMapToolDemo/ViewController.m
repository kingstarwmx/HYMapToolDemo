//
//  ViewController.m
//  HYMapToolDemo
//
//  Created by MrZhangKe on 16/3/25.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import "ViewController.h"
#import "HYMapViewController.h"
#import "HYRouteViewController.h"

@interface ViewController ()@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
    btn.frame = CGRectMake(100, 100, 200, 200);
    [btn setTitle:@"路线展示" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    btn.backgroundColor = [UIColor redColor];
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn1 addTarget:self action:@selector(tap1:) forControlEvents:UIControlEventTouchUpInside];
    btn1.frame = CGRectMake(100, 400, 200, 200);
    [btn1 setTitle:@"发送位置" forState:UIControlStateNormal];
    [self.view addSubview:btn1];
    btn1.backgroundColor = [UIColor redColor];
    
//    self.navigationController.navigationBar.translucent = NO;
    
}


- (IBAction)showMap:(UIButton *)sender {
    HYMapViewController *mapVC = [[HYMapViewController alloc] init];
    mapVC.title = @"位置";
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mapVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)tap1:(UIButton *)sender{
    HYMapViewController *mapVC = [[HYMapViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mapVC];
    mapVC.title = @"地图";
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)tap:(UIButton *)sender{

    
    HYRouteViewController *mapVC = [[HYRouteViewController alloc] init];
    mapVC.targetCoordinate = CLLocationCoordinate2DMake(30.551828,104.061833);
    mapVC.title = @"地图";
    [self.navigationController pushViewController:mapVC animated:YES];
}


@end
