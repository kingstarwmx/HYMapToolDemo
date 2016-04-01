//
//  HYCollectionButton.m
//  HYSelectViewDemo
//
//  Created by MrZhangKe on 16/3/24.
//  Copyright © 2016年 huayun. All rights reserved.
//

//图片高度跟label高度与图片的和之比
#define HYBUTTONIMAGERATIO 0.618

#import "HYCollectionButton.h"

@implementation HYCollectionButton

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
//        self.titleLabel.font = [UIFont systemFontOfSize:10];
        [self showGrid:YES];
    }
    return self;
}

- (void)showGrid:(BOOL)isShowGrid{
    if (isShowGrid) {
        //设置cell的阴影
        self.clipsToBounds = NO;
        self.layer.contentsScale = [UIScreen mainScreen].scale;
        self.layer.shadowOpacity = 0.9f;
        self.layer.shadowRadius = 0.7f;
        self.layer.shadowOffset = CGSizeMake(0,0);
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        //设置缓存
        self.layer.shouldRasterize = YES;
        //设置抗锯齿边缘
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect{
    CGFloat imageW = contentRect.size.width;
    CGFloat imageH = (contentRect.size.height - self.imageMargin - self.titleMargin) * HYBUTTONIMAGERATIO;
    return CGRectMake(0, self.imageMargin, imageW, imageH);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect{
    CGFloat titleY = (contentRect.size.height - self.imageMargin - self.titleMargin) * HYBUTTONIMAGERATIO + self.imageMargin;
    CGFloat titleW = contentRect.size.width;
    CGFloat titleH = (contentRect.size.height - self.imageMargin - self.titleMargin) * (1 - HYBUTTONIMAGERATIO);
    return CGRectMake(0, titleY, titleW, titleH);
}

- (CGFloat)imageMargin{
    if (!_imageMargin) {
        _imageMargin = 10.f;
    }
    return _imageMargin;
}

- (CGFloat)titleMargin{
    if (!_titleMargin) {
        _titleMargin = 5.f;
    }
    return _titleMargin;
}

- (void)setIsShowGrid:(BOOL)isShowGrid{
    _isShowGrid = isShowGrid;
    [self showGrid:isShowGrid];
}

@end
