//
//  HYMapViewController.m
//  HYMapToolDemo
//
//  Created by MrZhangKe on 16/3/28.
//  Copyright © 2016年 huayun. All rights reserved.
//

#import "HYMapViewController.h"
#import <MAMapKit/MAMapKit.h>

#import "MJRefresh.h"
#import "MapToolRefreshFooter.h"

#define MAPHEIGHT 320
#define SEACHBARHEIGHT 44
#define PINVIEWWIDTH 40

@interface HYMapViewController ()<MAMapViewDelegate, AMapSearchDelegate, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate>{
    UIView *_mapContainer;
    MAMapView *_mapView;
    
    AMapSearchAPI *_search;//搜索的API
    
    AMapPOIAroundSearchRequest *_request;//周边搜索请求
    AMapPOIKeywordsSearchRequest *_nameRequest;//关键字搜索请求
    
    UITableView *_listTableView;
    NSMutableArray *_POIArray;
    NSMutableArray *_searchArray;
    NSMutableArray *_moveArray;
    
    NSInteger _page;
    NSInteger _namePage;
    UISearchController *_searchController;
    UITableViewController * _searchResultsController;
    
    MAPointAnnotation *_pointAnnotation;
    
    AMapGeoPoint *_userLocationPoint;//当前用户所在的坐标
    AMapGeoPoint *_centerPoint;//地图中心点的坐标
    
    BOOL _isMoveRequest;//在移动地图需要刷新的时候判断是否是下拉刷新还是重新移动视图刷新
    
}

@property (nonatomic, assign) NSInteger selectedIndex;//listtableview cell的被选中序号
@property (nonatomic, assign) NSInteger selectedNameIndex;//listtableview cell的被选中序号

@end

@implementation HYMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _POIArray = [NSMutableArray array];
    _searchArray = [NSMutableArray array];
    _moveArray = [NSMutableArray array];
    NSLog(@"viewDidLoad");
    self.navigationController.navigationBar.translucent = NO;
    
    //设置_listTableView的第一个cell处于选中的状态
    self.selectedIndex = 0;
    //设置搜索的tableview的第一个cell处于未选中的状态
    self.selectedNameIndex = -1;
    
    //设置页面的格式
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStylePlain target:self action:@selector(send:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    [self initSearch];
    //构造AMapPOIAroundSearchRequest对象，设置周边请求参数
    [self initAMapPOIAroundSearchRequest];
    
    //关键字搜索请求初始化
    [self initAMapPOIKeywordsSearchRequest];

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initMap];
    
    //初始化自定义大头针
    [self initPinImageView];
    
    [self initSearchController];
    
    [self initTableView];
    
    [self initbackButton];
    //初始化大头针
    //    [self initAnnotation];
    
}

- (void)cancel:(UIBarButtonItem *)item{
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)send:(UIBarButtonItem *)item{
    UIImage *image = [_mapView takeSnapshotInRect:CGRectMake(0, SEACHBARHEIGHT, self.view.bounds.size.width, MAPHEIGHT)];
    self.block(image, _centerPoint);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoUserLocation:(UIButton *)sender{
    
    if (_userLocationPoint) {
        [self transformToPoint:_userLocationPoint];
        NSLog(@"gotoUserLocation");
    }
}

- (void)transformToPoint:(AMapGeoPoint *)point{
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(point.latitude, point.longitude);
    MACoordinateRegion region = MACoordinateRegionMake(location, _mapView.region.span);
    
    [_mapView setRegion:region animated:YES];
}

#pragma mark -- 初始化控件的方法 --

- (void)initbackButton{
    UIButton *currentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [currentBtn setBackgroundImage:[UIImage imageNamed:@"map_update_user_location"] forState:UIControlStateNormal];
    currentBtn.frame = CGRectMake(self.view.bounds.size.width - 60, SEACHBARHEIGHT + MAPHEIGHT - 60, 40, 40);
    [currentBtn addTarget:self action:@selector(gotoUserLocation:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:currentBtn];
}

- (void)initPinImageView{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    UIImage *image = [UIImage imageNamed:@"map_location_pin_conversation"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.bounds = CGRectMake(0, 0, PINVIEWWIDTH, PINVIEWWIDTH);
    imageView.center = CGPointMake(screenSize.width / 2, MAPHEIGHT / 2 + SEACHBARHEIGHT - 15);
    [self.view addSubview:imageView];
}



- (void)initSearch{
    //搜索API
    //初始化检索对象
    [AMapSearchServices sharedServices].apiKey = @"beb3637f15fef6621719825838a5eb3c";
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
}

- (void)initAMapPOIKeywordsSearchRequest{
    _nameRequest = [[AMapPOIKeywordsSearchRequest alloc] init];
    _nameRequest.sortrule = 0;
    _nameRequest.requireExtension = YES;
    _nameRequest.types = @"商务住宅|道路附属设施";
    _nameRequest.city = @"成都";
    _nameRequest.cityLimit = YES;
    _nameRequest.page = _namePage;
}

- (void)initAMapPOIAroundSearchRequest{
    _request = [[AMapPOIAroundSearchRequest alloc] init];
    _request.location = [AMapGeoPoint locationWithLatitude:30.544906 longitude:104.065731];
    _request.page = _page;
    //    request.keywords = @"方恒";
    _request.types = @"商务住宅|道路附属设施";
    _request.sortrule = 0;
    _request.requireExtension = YES;
}


- (void)initSearchController{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    //初始化searchBar
    UITableViewController *searchResultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    _searchResultsController = searchResultsController;
    searchResultsController.tableView.mj_footer = [MapToolRefreshFooter footerWithRefreshingBlock:^{
        //发起关键字搜索
        [_search AMapPOIKeywordsSearch: _nameRequest];
        _namePage += 1;
        _nameRequest.page = _namePage;
    }];
    
    searchResultsController.tableView.dataSource = self;
    searchResultsController.tableView.delegate = self;
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.definesPresentationContext = YES;
    _searchController.searchBar.frame = CGRectMake(0, 0, screenSize.width, SEACHBARHEIGHT);
    _searchController.searchBar.tintColor = [UIColor whiteColor];
    [_searchController.searchBar sizeToFit];
    [self.view addSubview:_searchController.searchBar];
    
    
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate = self;

}

- (void)initTableView{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    
    //初始化tableView
    _listTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, MAPHEIGHT + SEACHBARHEIGHT, screenSize.width, screenSize.height - SEACHBARHEIGHT - MAPHEIGHT) style:UITableViewStylePlain];
    _listTableView.delegate = self;
    _listTableView.dataSource = self;
    [self.view addSubview:_listTableView];
    
    MapToolRefreshFooter *footer = [MapToolRefreshFooter footerWithRefreshingTarget:self refreshingAction:@selector(currentPOIAroundSearch)];
    _listTableView.mj_footer = footer;
    [_listTableView.mj_footer beginRefreshing];
}

- (void)currentPOIAroundSearch{
    _request.location = _centerPoint;
    [_search AMapPOIAroundSearch: _request];
    _page += 1;
    _request.page = _page;
}



- (void)initAnnotation{
    //设置大头针
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    //    pointAnnotation.coordinate = _mapView.centerCoordinate;
    pointAnnotation.title = @"方恒国际";
    pointAnnotation.subtitle = @"阜通东大街6号";
    _pointAnnotation = pointAnnotation;
    [_mapView addAnnotation:pointAnnotation];
}



- (void)initMap{
    //配置用户Key
    [MAMapServices sharedServices].apiKey = @"beb3637f15fef6621719825838a5eb3c";
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, SEACHBARHEIGHT, CGRectGetWidth(self.view.bounds), MAPHEIGHT)];
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    _mapView.showsUserLocation = YES;
    _mapView.showsScale = YES;
    _mapView.scaleOrigin = CGPointMake(63, MAPHEIGHT - 27);
    _mapView.distanceFilter = 20.f;
    [_mapView setZoomLevel:14.6 animated:YES];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
}




#pragma  mark -- UISearchResultsUpdating --
//
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    
    NSString *searchText = [searchController.searchBar text];
    if(![searchText length] > 0) {
        
        return;
    }
    else {
        [_searchArray removeAllObjects];
        [_searchResultsController.tableView reloadData];
        NSLog(@"%@", searchText);
        _nameRequest.keywords = searchText;
        
        [_search AMapPOIKeywordsSearch: _nameRequest];

    }
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
    if (request == _request) {

            for (AMapPOI *p in response.pois) {
                [_POIArray addObject:p];
            }
    }else if(request == _nameRequest){
        //地图调用关键字搜索返回的数据
        for (AMapPOI *p in response.pois) {
            [_searchArray addObject:p];
        }
    }
    [_listTableView.mj_footer endRefreshing];
    [_searchResultsController.tableView.mj_footer endRefreshing];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_listTableView reloadData];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_searchResultsController.tableView reloadData];
    });
    
}

#pragma mark -- MAMapViewDelegate --

-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation
updatingLocation:(BOOL)updatingLocation
{
    if(updatingLocation)
    {
        
        //取出当前位置的坐标
        _userLocationPoint = [AMapGeoPoint locationWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
        _centerPoint = _userLocationPoint;
        
        NSLog(@"userLocationPoint.latitude:%lf--userLocationPoint.longitude:%lf", _userLocationPoint.latitude, _userLocationPoint.longitude);
        NSLog(@"---------");
        NSLog(@"didUpdateUserLocation");
    }
}

//地图的范围改变的回调
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    _pointAnnotation.coordinate = _mapView.centerCoordinate;
    _centerPoint = [AMapGeoPoint locationWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
    NSLog(@"centerPoint.latitude:%lf--centerPoint.longitude:%lf", _centerPoint.latitude, _centerPoint.longitude);
    
    if (_isMoveRequest) {
        self.selectedIndex = 0;
        [_POIArray removeAllObjects];
        [_listTableView reloadData];
        [_listTableView.mj_footer beginRefreshing];
        //        [self currentPOIAroundSearch];
    }
    _isMoveRequest = YES;
    _page = 0;
}


//圆圈
- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MAAnnotationView *view = views[0];
    
    // 放到该方法中用以保证userlocation的annotationView已经添加到地图上了。
    if ([view.annotation isKindOfClass:[MAUserLocation class]])
    {
        MAUserLocationRepresentation *pre = [[MAUserLocationRepresentation alloc] init];
        pre.showsAccuracyRing = YES;
        pre.fillColor = [UIColor colorWithRed:0.28 green:0.55 blue:0.9 alpha:0.4];
//        pre.image = [UIImage imageNamed:@"[标记]01-注册"];
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
    AMapPOI *poi = nil;
    if (tableView == _searchResultsController.tableView) {
        if (_searchArray.count != 0) {
            poi = _searchArray[indexPath.row];
            if (self.selectedNameIndex == indexPath.row) {
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"setting_checked"]];
            }else{
                cell.accessoryView.hidden = YES;
            }
        }
    }else{
        if (_POIArray.count != 0) {
            poi = _POIArray[indexPath.row];
            if (self.selectedIndex == indexPath.row) {
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"setting_checked"]];
            }else{
                cell.accessoryView.hidden = YES;
            }
        }
    }
    BOOL isZero = indexPath.row == 0;
    NSString *strIndex0 = @"[位置]";
    
    cell.textLabel.text = isZero ? strIndex0:poi.name;
    cell.detailTextLabel.text = poi.address;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == _searchResultsController.tableView){
        return _searchArray.count;
    }else{
        return _POIArray.count;
    }
    return 0;
}



#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == _listTableView) {
        _isMoveRequest = NO;
        //单选
        if (self.selectedIndex == indexPath.row) {
            return;
        }
        self.selectedIndex = indexPath.row;
        [_listTableView reloadData];
        
        AMapPOI *poi = _POIArray[indexPath.row];
        AMapGeoPoint *point = poi.location;
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(point.latitude, point.longitude);
        MACoordinateRegion region = MACoordinateRegionMake(location, _mapView.region.span);
        
        [_mapView setRegion:region animated:YES];
    }else{
        _isMoveRequest = YES;
        if (self.selectedNameIndex == indexPath.row) {
            return;
        }
        self.selectedNameIndex = -1;
        [_searchResultsController.tableView reloadData];
        
        AMapPOI *poi = _searchArray[indexPath.row];
        AMapGeoPoint *point = poi.location;
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(point.latitude, point.longitude);
        MACoordinateRegion region = MACoordinateRegionMake(location, _mapView.region.span);
        _searchController.active = NO;
        
        [_mapView setRegion:region animated:YES];
    }
}

@end
