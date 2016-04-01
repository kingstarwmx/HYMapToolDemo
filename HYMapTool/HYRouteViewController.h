//
//  HYRouteViewController.h
//  HYMapToolDemo
//
//  Created by MrZhangKe on 16/3/31.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

@interface HYRouteViewController : UIViewController

typedef NS_ENUM(NSInteger, AMapRoutePlanningType)
{
    AMapRoutePlanningTypeDrive = 0,
    AMapRoutePlanningTypeWalk,
    AMapRoutePlanningTypeBus
};

/** 目标位置 */
@property (nonatomic, assign) CLLocationCoordinate2D targetCoordinate;

/** 路径规划类型,默认是步行 */
@property (nonatomic) AMapRoutePlanningType routePlanningType;

@end
