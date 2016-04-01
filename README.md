###HYMapTool:
##1.HYRouteViewController:用来显示路线，传入一个坐标可以显示从当前位置到该坐标的路线图
##2.HYMapViewController:类似微信的的发送位置界面,还可以提供当前位置截图
    __block typeof(self) weakSelf = self;
        HYMapViewController *mapVC = [[HYMapViewController alloc] init];
        mapVC.block = ^(UIImage *image){
            weakSelf.imageView.image = image;
        };