//
//  HYCollectionPicker.h
//  HYSelectViewDemo
//
//  Created by MrZhangKe on 16/3/22.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^HYCollectionPickerBlock)(NSInteger itemIndex);

@interface HYCollectionPicker : UIView

/**动画的持续时间，默认是0.3*/
@property (nonatomic, assign) CGFloat animationDuration;

/**背景视图的透明度，默认0.3*/
@property (nonatomic, assign) CGFloat backgroundOpacity;

/**单元格cell的颜色，默认是纯白*/
@property (nonatomic, strong) UIColor *collectionBGColor;

/**单元格文字的颜色，默认是灰色*/
@property (nonatomic, strong) UIColor *titleColor;

/** title的字体样式,默认是系统11号字体 */
@property (nonatomic, strong) UIFont *titleFont;

/**每行的列数,默认是4*/
@property (nonatomic, assign) NSInteger column;

/** pageControl的高度，默认是25 */
@property (nonatomic, assign) CGFloat pageControlH;

/**行数,默认不固定，根据传入的title和imageName的数量确定，最多是2最少是1*/
//@property (nonatomic, assign) NSInteger row;

/**
 *  单元格的宽高比,默认是1.3
 * tips: 当设置了cellHeight时，cellRatio失效
 */
@property (nonatomic, assign) CGFloat cellRatio;

/**
 *  cell的高度,默认不是固定的值，根据宽度来确定的，cell宽高比默认是1.3
 * tips: 当设置了cellHeight时，cellRatio失效
 */
@property (nonatomic, assign) NSInteger cellHeight;


/**
 *  返回一个 HYCollectionPicker 对象, 类方法
 *
 *  @param title          所有按钮的标题
 *  @param imageNames     所有按钮的图片名字
 *  @param clickedBlock   点击按钮的 block 回调
 */
+ (instancetype)pickerWithTitles:(NSArray *)titles
                          images:(NSArray *)imageNames
                         clicked:(HYCollectionPickerBlock)clickedBlock;

/**
 *  返回一个 HYCollectionPicker 对象, 对象方法
 *
 *  @param title          所有按钮的标题
 *  @param imageNames     所有按钮的图片名字
 *  @param clickedBlock   点击按钮的 block 回调
 */
- (instancetype)initWithTitles:(NSArray *)titles
                          images:(NSArray *)imageNames
                         clicked:(HYCollectionPickerBlock)clickedBlock;

/**显示 CollectionPicker*/
- (void)show;

@end
