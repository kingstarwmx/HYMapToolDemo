//
//  HYCollectionPicker.m
//  HYSelectViewDemo
//
//  Created by MrZhangKe on 16/3/22.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import "HYCollectionPicker.h"
#import "HYCollectionButton.h"

#define CollectionHeight 100
#define PC_DEFAULT_BACKGROUND_OPACITY 0.3f
#define PC_DEFAULT_ANIMATION_DURATION 0.3f

@interface HYCollectionPicker ()<UIScrollViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIWindow *backWindow;
@property (nonatomic, strong) UIView *darkView;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) NSArray *imageNames;
@property (nonatomic, copy) HYCollectionPickerBlock pickerBlock;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *bottomView;//装底部视图跟按钮的容器视图
@property (nonatomic, assign) NSInteger pageCount;

@end

@implementation HYCollectionPicker


+ (instancetype)pickerWithTitles:(NSArray *)titles
                          images:(NSArray *)imageNames
                         clicked:(HYCollectionPickerBlock)clickedBlock{
    return [[self alloc] initWithTitles:titles images:imageNames clicked:clickedBlock];
}

- (instancetype)initWithTitles:(NSArray *)titles
                        images:(NSArray *)imageNames
                       clicked:(HYCollectionPickerBlock)clickedBlock{
    self = [super init];
    if (self) {
        self.titles = titles;
        self.imageNames = imageNames;
        self.pickerBlock = clickedBlock;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setUpViews{
    
    //计算一些基本的数据
    NSInteger pageCount = (self.titles.count + self.column * 2 - 1 ) / (self.column * 2);//取整
    self.pageCount = pageCount;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    NSInteger maxRow = 0;
    if (self.titles.count <= self.column) {
        maxRow = 1;
    }else{
        maxRow = 2;
    }
    CGFloat cellWidth = screenSize.width / self.column;
    CGFloat cellHeight = cellWidth / self.cellRatio;
    if (self.cellHeight) {
        cellHeight = self.cellHeight;
    }
    
    //设置自身属性
    self.userInteractionEnabled = YES;
    self.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);
    
    //初始化darkView
    UIView *darkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    darkView.alpha = 0.f;
    darkView.backgroundColor = [UIColor blackColor];
    darkView.userInteractionEnabled = YES;
    [self addSubview:darkView];
    self.darkView = darkView;
    //设置darkView点击事件
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [darkView addGestureRecognizer:tap];
    
    //初始化scrollView
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.frame = CGRectMake(0, 0, screenSize.width, cellHeight * maxRow);
    scrollView.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.bounces = NO;
    scrollView.pagingEnabled = YES;
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(screenSize.width * pageCount,  cellHeight * maxRow);
    self.scrollView = scrollView;
    
    //设置scrollView里面的按钮
    for (int i = 0; i < self.titles.count; i ++) {
        HYCollectionButton *btn = [[HYCollectionButton alloc] init];
        btn.tag = i;
        [btn setTitle:self.titles[i] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:self.imageNames[i]] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitleColor:self.titleColor forState:UIControlStateNormal];
        [btn setTitleColor:self.titleColor forState:UIControlStateHighlighted];
        [btn.titleLabel setFont:self.titleFont];
        
        btn.isShowGrid = YES;
        CGFloat btnX = screenSize.width * (i / (self.column * 2)) + cellWidth * (i % self.column);
        CGFloat btnY = cellHeight * ((i % (self.column * 2)) / self.column);
        CGFloat btnW = cellWidth;
        CGFloat btnH = cellHeight;
        btn.frame = CGRectMake(btnX, btnY, btnW, btnH);
        NSLog(@"%d-----%@", i, NSStringFromCGRect(btn.frame));
        [scrollView addSubview:btn];
    }
    
    //初始化pagecontrol
    CGFloat pageControlH = 0;
    if (pageCount > 1) {
        pageControlH = self.pageControlH;
        UIPageControl *pageControl = [[UIPageControl alloc] init];
        self.pageControl = pageControl;
        pageControl.frame = CGRectMake(0, CGRectGetMaxY(scrollView.frame), screenSize.width, pageControlH);
        pageControl.numberOfPages = pageCount;
        pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:0.9 alpha:1];
        pageControl.currentPageIndicatorTintColor = [UIColor colorWithWhite:0.4 alpha:1];
        pageControl.userInteractionEnabled = NO;
    }
    
    //初始化bottomView
    UIView *bottomView = [[UIView alloc] init];
    CGFloat bottomViewH = scrollView.bounds.size.height + pageControlH;
    bottomView.frame = CGRectMake(0, screenSize.height - bottomViewH, screenSize.width, bottomViewH);
    bottomView.backgroundColor = self.collectionBGColor;
    [bottomView addSubview:scrollView];
    [bottomView addSubview:self.pageControl];
    self.bottomView = bottomView;
    
    CGAffineTransform VerticalTransform = CGAffineTransformMakeTranslation(0, bottomView.bounds.size.height);
    bottomView.transform = VerticalTransform;
}

//- (void)changePage:(UIPageControl *)sender{
//    [self.collectionView setContentOffset:CGPointMake(sender.currentPage * [UIScreen mainScreen].bounds.size.width, 0)];
//}

#pragma mark --- UIScrollViewDelegate ---

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat currentPageIndex = (scrollView.contentOffset.x + screenW / 2 ) / screenW;
    self.pageControl.currentPage = currentPageIndex;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

}


- (void)btnClicked:(UIButton *)sender{
    [self dismiss:nil];
    if (self.pickerBlock) {
        self.pickerBlock(sender.tag);
    }
}

- (void)show{
    [self setUpViews];
    
    self.backWindow.hidden = NO;
    
    [self addSubview:self.bottomView];
    [self.backWindow addSubview:self];
    
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.bottomView.transform = CGAffineTransformIdentity;
        self.darkView.alpha = self.backgroundOpacity;
    } completion:^(BOOL finished) {
        self.darkView.userInteractionEnabled = YES;
    }];
}

- (void)dismiss:(UITapGestureRecognizer *)tap {
    
    [self.darkView setUserInteractionEnabled:YES];
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        [self.darkView setAlpha:0];
        
        CGRect frame = self.bottomView.frame;
        frame.origin.y += frame.size.height;
        [self.bottomView setFrame:frame];
        
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
        
        self.backWindow.hidden = YES;
    }];
}

#pragma mark -- getter --

- (UIWindow *)backWindow {
    
    if (_backWindow == nil) {
        
        _backWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _backWindow.windowLevel       = UIWindowLevelStatusBar;
        _backWindow.backgroundColor   = [UIColor clearColor];
        _backWindow.hidden = NO;
    }
    
    return _backWindow;
}

- (CGFloat)backgroundOpacity{
    if (!_backgroundOpacity) {
        _backgroundOpacity = PC_DEFAULT_BACKGROUND_OPACITY;
    }
    return _backgroundOpacity;
}

- (CGFloat)animationDuration{
    if (!_animationDuration) {
        _animationDuration = PC_DEFAULT_ANIMATION_DURATION;
    }
    return _animationDuration;
}

- (UIColor *)collectionBGColor{
    if (!_collectionBGColor) {
        _collectionBGColor = [UIColor colorWithWhite:1 alpha:1];
    }
    return _collectionBGColor;
}

- (CGFloat)cellRatio{
    if (!_cellRatio) {
        _cellRatio = 1.3f;
    }
    return _cellRatio;
}

//- (BOOL)isShowGrid{
//    if (!_isShowGrid) {
//        _isShowGrid = NO;
//    }
//    return _isShowGrid;
//}

- (NSInteger)column{
    if (!_column) {
        _column = 4;
    }
    return _column;
}

- (UIColor *)titleColor{
    if (!_titleColor) {
        _titleColor = [UIColor grayColor];
    }
    return _titleColor;
}

- (UIFont *)titleFont{
    if (!_titleFont) {
        _titleFont = [UIFont systemFontOfSize:11];
    }
    return _titleFont;
}

- (CGFloat)pageControlH{
    if (!_pageControlH) {
        _pageControlH = 25;
    }
    return _pageControlH;
}

@end



