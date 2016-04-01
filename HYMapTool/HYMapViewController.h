//
//  HYMapViewController.h
//  HYMapToolDemo
//
//  Created by MrZhangKe on 16/3/28.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

typedef void(^takeSnapshotBlock)(UIImage *image, AMapGeoPoint *selectedPoint);

@interface HYMapViewController : UIViewController

@property (nonatomic, copy) takeSnapshotBlock block;

@end
