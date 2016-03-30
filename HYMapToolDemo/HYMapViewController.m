//
//  HYMapViewController.m
//  HYMapToolDemo
//
//  Created by MrZhangKe on 16/3/28.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import "HYMapViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "MJRefresh.h"

#define MAPHEIGHT [UIScreen mainScreen].bounds.size.height / 2
#define SEACHBARHEIGHT 44

@interface HYMapViewController ()<MAMapViewDelegate, AMapSearchDelegate, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate>{
    UIView *_mapContainer;
    MAMapView *_mapView;
    AMapSearchAPI *_search;
    UITableView *_listTableView;
    NSMutableArray *_POIArray;
    AMapPOIAroundSearchRequest *_request;
    NSInteger _page;
    UISearchController *_searchController;
}


@end

@implementation HYMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _POIArray = [NSMutableArray array];
    
    NSLog(@"viewDidLoad");
    
    //设置页面的格式
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] init];
    leftItem.title = @"取消";
    
    //搜索API
    //初始化检索对象
    [AMapSearchServices sharedServices].apiKey = @"beb3637f15fef6621719825838a5eb3c";
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
    //构造AMapPOIAroundSearchRequest对象，设置周边请求参数
    _request = [[AMapPOIAroundSearchRequest alloc] init];
    _request.location = [AMapGeoPoint locationWithLatitude:30.544906 longitude:104.065731];
    _request.page = _page;
    //    request.keywords = @"方恒";
    _request.types = @"商务住宅|道路附属设施";
    _request.sortrule = 0;
    _request.requireExtension = YES;
    
    
    
    //发起周边搜索
//    [_search AMapPOIAroundSearch: _request];
    
   
}

- (void)btnClicked:(UIButton *)sender{
    [_search AMapPOIAroundSearch: _request];
    _page += 1;
    _request.page = _page;
    
//    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)loadMoreData{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_search AMapPOIAroundSearch: _request];
    });
    
    _page += 1;
    _request.page = _page;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.view.backgroundColor = [UIColor whiteColor];
    NSLog(@"viewDidAppear");
    
    _mapContainer = [[UIView alloc] initWithFrame:CGRectMake(0, SEACHBARHEIGHT, CGRectGetWidth(self.view.bounds), MAPHEIGHT)];
    [self.view addSubview:_mapContainer];
    
    //配置用户Key
    [MAMapServices sharedServices].apiKey = @"beb3637f15fef6621719825838a5eb3c";
//    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, SEACHBARHEIGHT, CGRectGetWidth(self.view.bounds), MAPHEIGHT)];
    _mapView = [[MAMapView alloc] init];
    _mapView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), MAPHEIGHT);
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    _mapView.showsUserLocation = YES;
    _mapView.showsScale = NO;
    [_mapView setZoomLevel:16.1 animated:YES];
    _mapView.delegate = self;
    [_mapContainer addSubview:_mapView];
    
    CLLocationCoordinate2D localtion = _mapView.centerCoordinate;
    
    NSLog(@"latitude : %f,longitude: %f", localtion.latitude,localtion.longitude);
    
    //设置大头针
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = CLLocationCoordinate2DMake(39.911952, 116.405898);
    pointAnnotation.title = @"方恒国际";
    pointAnnotation.subtitle = @"阜通东大街6号";
    [_mapView addAnnotation:pointAnnotation];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    btn.frame = CGRectMake(100, 100, 50, 50);
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    //初始化searchBar
    UITableViewController *searchResultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    searchResultsController.tableView.dataSource = self;
    searchResultsController.tableView.delegate = self;
    _searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.definesPresentationContext = YES;
    _searchController.searchBar.frame = CGRectMake(0, 20, screenSize.width, SEACHBARHEIGHT);
    _searchController.searchBar.tintColor = [UIColor whiteColor];
    [self.view addSubview:_searchController.searchBar];
    
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate = self;
    
    //初始化tableView
    _listTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, SEACHBARHEIGHT + MAPHEIGHT, screenSize.width, screenSize.height - SEACHBARHEIGHT - MAPHEIGHT) style:UITableViewStylePlain];
    _listTableView.delegate = self;
    _listTableView.dataSource = self;
    [self.view addSubview:_listTableView];
    
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    _listTableView.mj_footer = footer;
    [_listTableView.mj_footer beginRefreshing];
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSLog(@"viewWillAppear");
}

#pragma mark -- AMapSearchDelegate --
//实现POI搜索对应的回调函数
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if(response.pois.count == 0)
    {
        return;
    }
    
    //通过 AMapPOISearchResponse 对象处理搜索结果
    NSString *strCount = [NSString stringWithFormat:@"count: %ld",(long)response.count];
    NSString *strSuggestion = [NSString stringWithFormat:@"Suggestion: %@", response.suggestion];
    NSString *strPoi = @"";
    for (AMapPOI *p in response.pois) {
        [_POIArray addObject:p];
        strPoi = [NSString stringWithFormat:@"%@\nPOI: %@ name:%@", strPoi, p.description, p.name];
    }
    
    [_listTableView.mj_footer endRefreshing];
    
    NSLog(@"%ld", response.pois.count);
    NSString *result = [NSString stringWithFormat:@"%@ \n %@ \n %@", strCount, strSuggestion, strPoi];
    NSLog(@"Place: %@", result);
    NSLog(@"%ld", _POIArray.count);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_listTableView reloadData];
    });
    
}


#pragma mark -- MAMapViewDelegate --

-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation
updatingLocation:(BOOL)updatingLocation
{
    if(updatingLocation)
    {
        //取出当前位置的坐标
        NSLog(@"latitude : %f,longitude: %f",userLocation.coordinate.latitude,userLocation.coordinate.longitude);
    }
}

//圆圈
- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MAAnnotationView *view = views[0];
    
    // 放到该方法中用以保证userlocation的annotationView已经添加到地图上了。
    if ([view.annotation isKindOfClass:[MAUserLocation class]])
    {
        MAUserLocationRepresentation *pre = [[MAUserLocationRepresentation alloc] init];
        pre.fillColor = [UIColor colorWithRed:0.28 green:0.55 blue:0.9 alpha:0.4];
        //        pre.strokeColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.9 alpha:1.0];
        pre.image = [UIImage imageNamed:@"location.png"];
        pre.lineWidth = 3;
        pre.lineDashPattern = @[@6, @3];
        
        [_mapView updateUserLocationRepresentation:pre];
        
        view.calloutOffset = CGPointMake(0, 0);
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



#pragma mark -- UITtableViewDataSource --

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *tableID = @"CELL";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:tableID];
    }
    AMapPOI *poi = _POIArray[indexPath.row];
    
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    NSLog(@"address:%@", poi.address);
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _POIArray.count;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return <#expression#>
//}

#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    NSDictionary *sectionItems = [self.tableSectionsAndItems objectAtIndex:indexPath.section];
//    
//    NSArray *namesForSection = [sectionItems objectForKey:[self.tableSections objectAtIndex:indexPath.section]];
//    
//    NSString *selectedItem = [namesForSection objectAtIndex:indexPath.row];
//    
//    //
//    NSLog(@"User selected %@", selectedItem);
}

@end
