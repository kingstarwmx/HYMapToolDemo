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
    
    AMapSearchAPI *_search;//搜索的API
    
    AMapPOIAroundSearchRequest *_request;//周边搜索请求
    AMapPOIKeywordsSearchRequest *_nameRequest;//关键字搜索请求
    AMapPOIAroundSearchRequest *_moveRequest;//移动地图的周边搜索请求
    
    UITableView *_listTableView;
    NSMutableArray *_POIArray;
    NSMutableArray *_searchArray;
    
    NSInteger _page;
    NSInteger _namePage;
    UISearchController *_searchController;
    UITableViewController * _searchResultsController;
    
    MAPointAnnotation *_pointAnnotation;
    AMapGeoPoint *_currentPoint;//当前指定的坐标
    BOOL _isCurrentRequest;//在移动地图需要刷新的时候判断是否是下拉刷新还是重新移动视图刷新
    
}

@property (nonatomic, assign) NSInteger selcetedIndex;//listtableview cell的被选中序号
@property (nonatomic, assign) NSInteger selcetedNameIndex;//listtableview cell的被选中序号

@end

@implementation HYMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _POIArray = [NSMutableArray array];
    _searchArray = [NSMutableArray array];
    NSLog(@"viewDidLoad");
    self.navigationController.navigationBar.translucent = NO;
    
    //设置页面的格式
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] init];
    leftItem.title = @"取消";
    
    [self initSearch];
    //构造AMapPOIAroundSearchRequest对象，设置周边请求参数
    [self initAMapPOIAroundSearchRequest];
    
    //关键字搜索请求初始化
    [self initAMapPOIKeywordsSearchRequest];
    
    //移动地图搜索请求初始化
    [self initMoveAMapPOIAroundSearchRequest];
    
    _isCurrentRequest = NO;
    
    [self initMap];
    
    [self initSearchController];
    
    [self initTableView];
    
    //初始化大头针
    [self initAnnotation];
    
}

- (void)initSearch{
    //搜索API
    //初始化检索对象
    [AMapSearchServices sharedServices].apiKey = @"beb3637f15fef6621719825838a5eb3c";
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
}

- (void)initMoveAMapPOIAroundSearchRequest{
    //移动地图搜索请求初始化
    _moveRequest = [[AMapPOIAroundSearchRequest alloc] init];
    //    _request.location = [AMapGeoPoint locationWithLatitude:30.544906 longitude:104.065731];
    _moveRequest.page = _page;
    //    request.keywords = @"方恒";
    _moveRequest.types = @"商务住宅|道路附属设施";
    _moveRequest.sortrule = 0;
    _moveRequest.requireExtension = YES;
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

//移动地图，listTableview的请求方法
- (void)loadMoreData:(AMapGeoPoint *)point{
    _moveRequest.location = point;
    if (!_isCurrentRequest) {
        _page = 0;
    }
    //发起周边搜索
    [_search AMapPOIAroundSearch: _moveRequest];
    
    _page += 1;
    _moveRequest.page = _page;
    _isCurrentRequest = YES;
}

- (void)initSearchController{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    //初始化searchBar
    UITableViewController *searchResultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    _searchResultsController = searchResultsController;
    searchResultsController.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        //发起关键字搜索
        [_search AMapPOIKeywordsSearch: _nameRequest];
        _namePage += 1;
        _nameRequest.page = _namePage;
    }];
    
    searchResultsController.tableView.dataSource = self;
    searchResultsController.tableView.delegate = self;
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.definesPresentationContext = YES;
    _searchController.searchBar.frame = CGRectMake(0, _searchController.searchBar.frame.origin.y, screenSize.width, 44.0);
    _searchController.searchBar.tintColor = [UIColor whiteColor];
    [_searchController.searchBar sizeToFit];
    [self.view addSubview:_searchController.searchBar];
    
    
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate = self;

}

- (void)initTableView{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    
    //初始化tableView
    _listTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, SEACHBARHEIGHT + MAPHEIGHT, screenSize.width, screenSize.height - SEACHBARHEIGHT - MAPHEIGHT) style:UITableViewStylePlain];
    _listTableView.delegate = self;
    _listTableView.dataSource = self;
    [self.view addSubview:_listTableView];
    
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        _request.location = _currentPoint;
        [_search AMapPOIAroundSearch: _request];
        _page += 1;
        _request.page = _page;
    }];
    _listTableView.mj_footer = footer;
    [_listTableView.mj_footer beginRefreshing];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.view.backgroundColor = [UIColor whiteColor];
    NSLog(@"viewDidAppear");
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
    _mapView.showsScale = NO;
    [_mapView setZoomLevel:16.1 animated:YES];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");
}



#pragma  mark -- UISearchResultsUpdating --
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
    NSString *strCount = [NSString stringWithFormat:@"count: %ld",(long)response.count];
    NSString *strSuggestion = [NSString stringWithFormat:@"Suggestion: %@", response.suggestion];
    NSString *strPoi = @"";
    if (request == _request) {
        
        for (AMapPOI *p in response.pois) {
            [_POIArray addObject:p];
            strPoi = [NSString stringWithFormat:@"%@\nPOI: %@ name:%@", strPoi, p.description, p.name];
        }
    }else if(request == _nameRequest){
        for (AMapPOI *p in response.pois) {
            [_searchArray addObject:p];
        }
    }else{
        
        if (!_isCurrentRequest) {
            [_searchArray removeAllObjects];
        }
        for (AMapPOI *p in response.pois) {
            [_searchArray addObject:p];
//            NSLog(@"移动地名:%@", p.name);
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
//        NSLog(@"latitude : %f,longitude: %f",userLocation.coordinate.latitude,userLocation.coordinate.longitude);
        _currentPoint = [AMapGeoPoint locationWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
        NSLog(@"---------");
        NSLog(@"didUpdateUserLocation");
    }
}


- (void)mapView:(MAMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    _isCurrentRequest = NO;
    
    _pointAnnotation.coordinate = _mapView.centerCoordinate;
    AMapGeoPoint *point = [AMapGeoPoint locationWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
    [self loadMoreData:point];
    NSLog(@"regionWillChangeAnimated");
}

- (void)mapView:(MAMapView *)mapView mapWillMoveByUser:(BOOL)wasUserAction{
    NSLog(@"mapWillMoveByUser");
}

- (void)mapView:(MAMapView *)mapView mapDidMoveByUser:(BOOL)wasUserAction{
    NSLog(@"mapDidMoveByUser");
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
    AMapPOI *poi = nil;
    if (tableView == _searchResultsController.tableView) {
        if (_searchArray.count != 0) {
            poi = _searchArray[indexPath.row];
//            NSLog(@"address:%@", poi.address);
        }
        
    }else{
        poi = _POIArray[indexPath.row];
    }
    
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    
    if (self.selcetedIndex == indexPath.row) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"setting_checked"]];
    }else{
        cell.accessoryView.hidden = YES;
    }
//    NSLog(@"searchArray.count:%ld", _searchArray.count);

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
        //单选
        if (self.selcetedIndex == indexPath.row) {
            return;
        }
        self.selcetedIndex = indexPath.row;
        [_listTableView reloadData];
        
        AMapPOI *poi = _POIArray[indexPath.row];
        AMapGeoPoint *point = poi.location;
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(point.latitude, point.longitude);
        MACoordinateRegion region = MACoordinateRegionMake(location, _mapView.region.span);
        
        [_mapView setRegion:region animated:YES];
    }else{
        if (self.selcetedNameIndex == indexPath.row) {
            return;
        }
        self.selcetedNameIndex = indexPath.row;
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
