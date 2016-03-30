//
//  TestViewController.m
//  HYMapToolDemo
//
//  Created by MrZhangKe on 16/3/30.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import "TestViewController.h"
#import <AMapSearchKit/AMapSearchKit.h>

@interface TestViewController ()<AMapSearchDelegate>{
    AMapSearchAPI *_nameSearch;
    AMapPOIKeywordsSearchRequest *_nameRequest;//关键字搜索请求
    
    NSMutableArray *_searchArray;
}

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _searchArray = [NSMutableArray array];
    
    //关键字搜索请求初始化
    [AMapSearchServices sharedServices].apiKey = @"beb3637f15fef6621719825838a5eb3c";
    _nameSearch = [[AMapSearchAPI alloc] init];
    _nameSearch.delegate = self;
    _nameRequest = [[AMapPOIKeywordsSearchRequest alloc] init];
    _nameRequest.sortrule = 0;
    _nameRequest.requireExtension = YES;
    _nameRequest.types = @"商务住宅|道路附属设施";
    _nameRequest.page = 1;
    _nameRequest.keywords = @"天府";
    _nameRequest.city = @"成都";
    _nameRequest.cityLimit = YES;
    [_nameSearch AMapPOIKeywordsSearch: _nameRequest];
}


- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    for (AMapPOI *p in response.pois) {
        [_searchArray addObject:p];
        NSLog(@"name:%@", p.name);
    }
    NSLog(@"%ld", _searchArray.count);
}

@end
