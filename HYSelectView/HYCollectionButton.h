//
//  HYCollectionButton.h
//  HYSelectViewDemo
//
//  Created by MrZhangKe on 16/3/24.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HYCollectionButton : UIButton

@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, assign) CGFloat titleMargin;
@property (nonatomic, assign) CGFloat imageMargin;
/**
 *  是否显示网格，默认是NO，不显示
 */
@property (nonatomic, assign) BOOL isShowGrid;

@end
