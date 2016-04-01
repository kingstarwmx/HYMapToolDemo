//
//  HYRouteViewController.m
//  HYMapToolDemo
//
//  Created by MrZhangKe on 16/3/31.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import "HYRouteViewController.h"
#import <MAMapKit/MAMapKit.h>
#import "MANaviRoute.h"
#import "CommonUtility.h"
#import "HYActionSheet.h"

#define BTNMARGIN 40
#define BTNWIDTH 40
#define RoutePlanningPaddingEdge 20
@interface HYRouteViewController ()<MAMapViewDelegate, AMapSearchDelegate>

/** 地图 */
@property (nonatomic, strong) MAMapView *mapView;
/** 搜索API */
@property (nonatomic, strong) AMapSearchAPI *search;
/** 当前位置点 */
@property (nonatomic, strong) AMapGeoPoint *currentPoint;
/** 当前位置 */
@property (nonatomic, strong) MAUserLocation *location;
/** 目标位置 */
@property (nonatomic, strong) AMapGeoPoint *targetPoint;

@property (nonatomic, strong) MAPointAnnotation *targetPointAnnotation;
/** 用于显示当前路线方案 */
@property (nonatomic) MANaviRoute * naviRoute;
/** 路径规划信息 */
@property (nonatomic, strong) AMapRoute *route;
/** 当前路线方案索引值 */
@property (nonatomic) NSInteger currentCourse;
/** 路线方案个数 */
@property (nonatomic) NSInteger totalCourse;

@property (nonatomic, assign) BOOL isLineShowed;

@end

@implementation HYRouteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"更多" style:UIBarButtonItemStylePlain target:self action:@selector(more:)];
    
    self.targetPoint = [AMapGeoPoint locationWithLatitude:self.targetCoordinate.latitude longitude:self.targetCoordinate.longitude];
    self.routePlanningType = AMapRoutePlanningTypeWalk;
    
    [self initSearch];
    [self ReGeocodeSearch];
    [self initMapView];
    [self initButtons];
    [self initAnnotion];
    [self transformToPoint:self.targetPoint];
}

/**在启动之后进行一次逆地理编码获取当前位置的信息*/
- (void)ReGeocodeSearch{
    //构造AMapReGeocodeSearchRequest对象
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = [AMapGeoPoint locationWithLatitude:self.targetCoordinate.latitude longitude:self.targetCoordinate.longitude];
    regeo.radius = 10000;
    regeo.requireExtension = YES;
    
    //发起逆地理编码
    [_search AMapReGoecodeSearch: regeo];
}

- (void)more:(UIBarButtonItem *)item{
    __block typeof(self) weakSelf = self;

    NSString *str = _isLineShowed ? @"隐藏路线":@"显示路线";
    HYActionSheet *sheet = [HYActionSheet sheetWithTitle:nil buttonTitles:@[str, @"苹果地图"] redButtonIndex:-1 clicked:^(NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            if (_isLineShowed) {
                [weakSelf clear];
                _isLineShowed = NO;
            }else{
                [weakSelf displayRouteLine];
                _isLineShowed = YES;
            }
        }
    }];
    [sheet show];
}

- (void)initButtons{
    
    //推到目标位置的按钮
    UIButton *desBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [desBtn setBackgroundImage:[UIImage imageNamed:@"map_update_target_location"] forState:UIControlStateNormal];
    desBtn.frame = CGRectMake(BTNMARGIN, self.view.bounds.size.height - (BTNMARGIN + BTNWIDTH) * 2, BTNWIDTH, BTNWIDTH);
    [desBtn addTarget:self action:@selector(gotoTarget:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:desBtn];
    
    //到用户所在位置的按钮
    UIButton *currentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [currentBtn setBackgroundImage:[UIImage imageNamed:@"map_update_user_location"] forState:UIControlStateNormal];
    currentBtn.frame = CGRectMake(BTNMARGIN, self.view.bounds.size.height - (BTNMARGIN + BTNWIDTH), BTNWIDTH, BTNWIDTH);
    [currentBtn addTarget:self action:@selector(gotoUserLocation:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:currentBtn];
}

- (void)displayRouteLine{
    self.routePlanningType = AMapRoutePlanningTypeWalk;
    
    self.route = nil;
    self.totalCourse   = 0;
    self.currentCourse = 0;
    
    [self clear];
    
    /* 发起路径规划搜索请求. */
    [self SearchNaviWithType:self.routePlanningType];
}

- (void)gotoTarget:(UIButton *)sender{
    
    if (self.targetPoint) {
        [self transformToPoint:self.targetPoint];
        NSLog(@"gotoTarget");
    }
}

- (void)gotoUserLocation:(UIButton *)sender{
    
    if (self.currentPoint) {
        [self transformToPoint:self.currentPoint];
        NSLog(@"gotoUserLocation");
    }
}

- (void)transformToPoint:(AMapGeoPoint *)point{
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(point.latitude, point.longitude);
    MACoordinateRegion region = MACoordinateRegionMake(location, self.mapView.region.span);
    
    [self.mapView setRegion:region animated:YES];
}



- (void)initAnnotion{
    //设置大头针上的显示气泡文字
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
//    pointAnnotation.title = @"";
//    pointAnnotation.subtitle = @"阜通东大街6号";
    pointAnnotation.coordinate = self.targetCoordinate;
    self.targetPointAnnotation = pointAnnotation;
    [_mapView addAnnotation:pointAnnotation];
    
}

- (void)initSearch{
    [AMapSearchServices sharedServices].apiKey = @"beb3637f15fef6621719825838a5eb3c";
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;
}

- (void)initMapView{
    //配置用户Key
    [MAMapServices sharedServices].apiKey = @"beb3637f15fef6621719825838a5eb3c";
    self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
    self.mapView.showsUserLocation = YES;
    self.mapView.showsScale = YES;
    self.mapView.logoCenter = CGPointMake(self.view.bounds.size.width - 50, self.view.bounds.size.height - 20);
    [self.mapView setZoomLevel:16.1 animated:YES];
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
}
#pragma mark -- AMapSearchDelegate --
/** 路径规划查询回调 */
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response{
    if (response.route == nil)
    {
        return;
    }
    
    self.route = response.route;
    [self presentCurrentCourse];
}

//逆向地理编码回调
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response{
    if(response.regeocode != nil)
    {
        //通过AMapReGeocodeSearchResponse对象处理搜索结果
        NSString *result = [NSString stringWithFormat:@"ReGeocode: %@ --%@", response.regeocode.formattedAddress, response.regeocode];
        self.targetPointAnnotation.title = response.regeocode.formattedAddress;
        NSLog(@"ReGeo: %@", result);
    }
}

#pragma mark -- MAMapViewDelegate --
//画线的回调
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    
    if ([overlay isKindOfClass:[LineDashPolyline class]])
    {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:((LineDashPolyline *)overlay).polyline];
        
        polylineRenderer.lineWidth   = 7;
        polylineRenderer.strokeColor = [UIColor blueColor];
        
        return polylineRenderer;
    }
    if ([overlay isKindOfClass:[MANaviPolyline class]])
    {
        MANaviPolyline *naviPolyline = (MANaviPolyline *)overlay;
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:naviPolyline.polyline];
        
        polylineRenderer.lineWidth = 8;
        
        if (naviPolyline.type == MANaviAnnotationTypeWalking)
        {
            polylineRenderer.strokeColor = self.naviRoute.walkingColor;
        }
        else
        {
            polylineRenderer.strokeColor = self.naviRoute.routeColor;
        }
        
        return polylineRenderer;
    }
    return nil;
}

-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation
updatingLocation:(BOOL)updatingLocation
{
    if(updatingLocation)
    {
        //取出当前位置的坐标
        self.currentPoint = [AMapGeoPoint locationWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
        
        NSLog(@"latitude:%lf-------longitude:%lf", userLocation.coordinate.latitude, userLocation.coordinate.longitude);
        
    }
}

//大头针
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        MAPinAnnotationView*annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        annotationView.canShowCallout= YES;       //设置气泡可以弹出，默认为NO
        annotationView.animatesDrop = YES;        //设置标注动画显示，默认为NO
        annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        annotationView.pinColor = MAPinAnnotationColorPurple;
        return annotationView;
    }
    return nil;
}

#pragma mark -------------------
/* 根据routePlanningType来执行响应的路径规划搜索*/
- (void)SearchNaviWithType:(AMapRoutePlanningType)searchType
{
    switch (searchType)
    {
        case AMapRoutePlanningTypeDrive:
        {
            [self searchRoutePlanningDrive];
            
            break;
        }
        case AMapRoutePlanningTypeWalk:
        {
            [self searchRoutePlanningWalk];
            
            break;
        }
        case AMapRoutePlanningTypeBus:
        {
            [self searchRoutePlanningBus];
            
            break;
        }
    }
}

/** 展示当前路线方案*/
- (void)presentCurrentCourse
{
    /* 公交路径规划. */
    if (self.routePlanningType == AMapRoutePlanningTypeBus)
    {
        self.naviRoute = [MANaviRoute naviRouteForTransit:self.route.transits[self.currentCourse]];
    }
    /* 步行，驾车路径规划. */
    else
    {
        
        
        MANaviAnnotationType type = self.routePlanningType == AMapRoutePlanningTypeDrive ? MANaviAnnotationTypeDrive : MANaviAnnotationTypeWalking;
        self.naviRoute = [MANaviRoute naviRouteForPath:self.route.paths[self.currentCourse] withNaviType:type];
    }
    
    [self.naviRoute addToMapView:self.mapView];
    
    /* 缩放地图使其适应polylines的展示. */
    [self.mapView setVisibleMapRect:[CommonUtility mapRectForOverlays:self.naviRoute.routePolylines]
                        edgePadding:UIEdgeInsetsMake(RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge)
                           animated:YES];
}


/* 驾车路径规划搜索. */
- (void)searchRoutePlanningDrive
{
    AMapDrivingRouteSearchRequest *navi = [[AMapDrivingRouteSearchRequest alloc] init];
    
    navi.requireExtension = YES;
    navi.strategy = 5;
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.currentPoint.latitude
                                           longitude:self.currentPoint.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.targetPoint.latitude
                                                longitude:self.targetPoint.longitude];
    
    [self.search AMapDrivingRouteSearch:navi];
}

/* 公交路径规划搜索. */
- (void)searchRoutePlanningBus
{
    AMapTransitRouteSearchRequest *navi = [[AMapTransitRouteSearchRequest alloc] init];
    
    navi.requireExtension = YES;
    navi.city             = @"chengdu";
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.currentPoint.latitude
                                           longitude:self.currentPoint.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.targetPoint.latitude
                                                longitude:self.targetPoint.longitude];
    
    [self.search AMapTransitRouteSearch:navi];
}

/* 步行路径规划搜索. */
- (void)searchRoutePlanningWalk
{
    AMapWalkingRouteSearchRequest *navi = [[AMapWalkingRouteSearchRequest alloc] init];
    
    /* 提供备选方案*/
    navi.multipath = 1;
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.currentPoint.latitude
                                           longitude:self.currentPoint.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.targetPoint.latitude
                                                longitude:self.targetPoint.longitude];
    
    [self.search AMapWalkingRouteSearch:navi];
}

/* 清空地图上已有的路线. */
- (void)clear
{
    [self.naviRoute removeFromMapView];
}

@end
