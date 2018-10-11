//
//  MainViewController.m
//  YBImageBrowserDemo
//
//  Created by 杨波 on 2018/9/13.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "MainViewController.h"
#import "MainImageCell.h"
#import "CustomCellData.h"
#import "YBIBUtilities.h"
#import "YBImageBrowserTipView.h"
#import "YBImageBrowser.h"
#import <SDWebImage/UIImageView+WebCache.h>

static NSString * const kReuseIdentifierOfMainImageCell = @"kReuseIdentifierOfMainImageCell";

@interface MainViewController () <UICollectionViewDataSource, UICollectionViewDelegate, YBImageBrowserDataSource, YBImageBrowserDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UISegmentedControl *segmentControl;
@property (nonatomic, copy) NSArray *dataArray;
@end

@implementation MainViewController



#pragma mark - 简要使用说明 / Brief instructions for use

/*
 'YBImageBrowser' 是图片浏览器的主体类，有两种方式为其赋值数据源：一种是直接设置 'dataSourceArray' 数组属性，一种设置 'dataSource' 代理实现协议方法。
 数据源个体为 'id<YBImageBrowserCellDataProtocol>' 类型，框架默认实现了两个类：'YBImageBrowseCellData'(图片) 和 'YBVideoBrowseCellData'(视频)，你只需要初始化它们并且以数组或者代理的方式赋值给 'YBImageBrowser' 实例变量。
 
 'YBImageBrowser'is the principal class of a image browser, and there are two ways to assign data sources to it: one is to set the 'dataSourceArray' array property directly, and the other is to set the 'dataSource' proxy and implementation protocol method.
 The framework implements two classes by default: 'YBImageBrowseCellData'(image) and 'YBVideoBrowseCellData'(video), you just initialize them and assign them to the 'YBImageBrowser' instance variable in an array or proxy.
 */

#pragma mark - Show 'YBImageBrowser' : Simple case

- (void)showBrowserForSimpleCaseWithIndex:(NSInteger)index {
    
    NSMutableArray *browserDataArr = [NSMutableArray array];
    [self.dataArray enumerateObjectsUsingBlock:^(NSString *_Nonnull urlStr, NSUInteger idx, BOOL * _Nonnull stop) {
        
        YBImageBrowseCellData *data = [YBImageBrowseCellData new];
        data.url = [NSURL URLWithString:urlStr];
        data.sourceObject = [self sourceObjAtIdx:idx];
        [browserDataArr addObject:data];
    }];
    
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSourceArray = browserDataArr;
    browser.currentIndex = index;
    [browser show];
}

#pragma mark - Show 'YBImageBrowser' : Mixed case

- (void)showBrowserForMixedCaseWithIndex:(NSInteger)index {
    
    NSMutableArray *browserDataArr = [NSMutableArray array];
    [self.dataArray enumerateObjectsUsingBlock:^(NSString *_Nonnull imageStr, NSUInteger idx, BOOL * _Nonnull stop) {

        // 此处只是为了判断测试用例的数据源是否为视频，并不是仅支持 MP4。/ This is just to determine whether the data source of the test case is video, not just MP4.
        if ([imageStr hasSuffix:@".MP4"]) {
            if ([imageStr hasPrefix:@"http"]) {
                
                // Type 1 : 网络视频 / Network video
                YBVideoBrowseCellData *data = [YBVideoBrowseCellData new];
                data.url = [NSURL URLWithString:imageStr];
                data.sourceObject = [self sourceObjAtIdx:idx];
                [browserDataArr addObject:data];
                
            } else {
                
                // Type 2 : 本地视频 / Local video
                NSString *path = [[NSBundle mainBundle] pathForResource:imageStr.stringByDeletingPathExtension ofType:imageStr.pathExtension];
                NSURL *url = [NSURL fileURLWithPath:path];
                YBVideoBrowseCellData *data = [YBVideoBrowseCellData new];
                data.url = url;
                data.sourceObject = [self sourceObjAtIdx:idx];
                [browserDataArr addObject:data];
                
            }
        } else if ([imageStr hasPrefix:@"http"]) {
            
            // Type 3 : 网络图片 / Network image
            YBImageBrowseCellData *data = [YBImageBrowseCellData new];
            data.url = [NSURL URLWithString:imageStr];
            data.sourceObject = [self sourceObjAtIdx:idx];
            [browserDataArr addObject:data];
            
        } else {
            
            // Type 4 : 本地图片 / Local image
            YBImageBrowseCellData *data = [YBImageBrowseCellData new];
            data.imageBlock = ^YBImage *{ return [YBImage imageNamed:imageStr]; };
            data.sourceObject = [self sourceObjAtIdx:idx];
            [browserDataArr addObject:data];
            
        }
    }];
    
    //Type 5 : 自定义 / Custom
    CustomCellData *data = [CustomCellData new];
    data.text = @"Custom Cell";
    [browserDataArr addObject:data];
    
    
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSourceArray = browserDataArr;
    browser.currentIndex = index;
    [browser show];
}


#pragma mark - Show 'YBImageBrowser' : System album

- (void)showBrowserForSystemAlbumWithIndex:(NSInteger)index {
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSource = self;
    browser.currentIndex = index;
    [browser show];
}

// <YBImageBrowserDataSource>

- (NSUInteger)yb_numberOfCellForImageBrowserView:(YBImageBrowserView *)imageBrowserView {
    return self.dataArray.count;
}

- (id<YBImageBrowserCellDataProtocol>)yb_imageBrowserView:(YBImageBrowserView *)imageBrowserView dataForCellAtIndex:(NSUInteger)index {
    PHAsset *asset = (PHAsset *)self.dataArray[index];
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        
        // Type 1 : 系统相册的视频 / Video of system album
        YBVideoBrowseCellData *data = [YBVideoBrowseCellData new];
        data.phAsset = asset;
        data.sourceObject = [self sourceObjAtIdx:index];

        return data;
    } else if (asset.mediaType == PHAssetMediaTypeImage) {
        
        // Type 2 : 系统相册的图片 / Image of system album
        YBImageBrowseCellData *data = [YBImageBrowseCellData new];
        data.phAsset = asset;
        data.sourceObject = [self sourceObjAtIdx:index];

        return data;
    }
    return nil;
}


#pragma mark - Tool

- (id)sourceObjAtIdx:(NSInteger)idx {
    MainImageCell *cell = (MainImageCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
    return cell ? cell.mainImageView : nil;
}


// -----------------------------------------------------------



#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController.navigationBar.topItem setTitleView:self.segmentControl];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.clearButton];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - click event

- (void)clickSegmentControl:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0: {
            self.dataArray = @[@"http://img4.duitang.com/uploads/item/201601/15/20160115231312_TWuG5.gif",
                               @"http://c.hiphotos.baidu.com/baike/pic/item/d1a20cf431adcbefd4018f2ea1af2edda3cc9fe5.jpg",
                               @"http://img3.duitang.com/uploads/item/201605/28/20160528202026_BvuWP.jpeg",
                               @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118823131&di=aa588a997ac0599df4e87ae39ebc7406&imgtype=0&src=http%3A%2F%2Fimg3.duitang.com%2Fuploads%2Fitem%2F201605%2F08%2F20160508154653_AQavc.png",
                               @"https://ss0.bdstatic.com/70cFvHSh_Q1YnxGkpoWK1HF6hhy/it/u=722693321,3238602439&fm=27&gp=0.jpg",
                               @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118892596&di=5e8f287b5c62ca0c813a548246faf148&imgtype=0&src=http%3A%2F%2Fwx1.sinaimg.cn%2Fcrop.0.0.1080.606.1000%2F8d7ad99bly1fcte4d1a8kj20u00u0gnb.jpg",
                               @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118914981&di=7fa3504d8767ab709c4fb519ad67cf09&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201410%2F05%2F20141005221124_awAhx.jpeg",
                               @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118934390&di=fbb86678336593d38c78878bc33d90c3&imgtype=0&src=http%3A%2F%2Fi2.hdslb.com%2Fbfs%2Farchive%2Fe90aa49ddb2fa345fa588cf098baf7b3d0e27553.jpg",
                               @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118984884&di=7c73ddf9d321ef94a19567337628580b&imgtype=0&src=http%3A%2F%2Fimg5q.duitang.com%2Fuploads%2Fitem%2F201506%2F07%2F20150607185100_XQvYT.jpeg"];
        }
            break;
        case 1: {
            self.dataArray = @[@"localImage0.jpeg",
                               @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118803027&di=beab81af52d767ebf74b03610508eb36&imgtype=0&src=http%3A%2F%2Fe.hiphotos.baidu.com%2Fbaike%2Fpic%2Fitem%2F2e2eb9389b504fc2995aaaa1efdde71190ef6d08.jpg",
                               @"video0.MP4",
                               @"https://aweme.snssdk.com/aweme/v1/playwm/?video_id=v0200ff00000bdkpfpdd2r6fb5kf6m50&line=0.MP4",
                               @"localGifImage0.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"localGifImage1.gif",
                               @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1524118772581&di=29b994a8fcaaf72498454e6d207bc29a&imgtype=0&src=http%3A%2F%2Fimglf2.ph.126.net%2F_s_WfySuHWpGNA10-LrKEQ%3D%3D%2F1616792266326335483.gif",
                               @"localBigImage0.jpeg",
                               @"localLongImage0.jpeg",
                               @"localLongImage0.jpeg",
                               @"localLongImage0.jpeg",
                               @"localLongImage0.jpeg",
                               @"localLongImage0.jpeg",
                               @"localLongImage0.jpeg",
                               @"localLongImage0.jpeg",
                               @"localLongImage0.jpeg",
                               @"localLongImage0.jpeg"];
        }
            break;
        case 2: {
            self.dataArray = [self.class getPHAssets];
        }
            break;
    }
    if (self.collectionView.superview) [self.collectionView reloadData];
}

- (void)clickClearButton:(UIButton *)sender {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        [YBIBGetNormalWindow() yb_showHookTipView:@"Clear successful"];
    }];
}

#pragma mark - <UICollectionViewDataSource, UICollectionViewDelegate>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MainImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifierOfMainImageCell forIndexPath:indexPath];
    cell.data = self.dataArray[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.segmentControl.selectedSegmentIndex) {
        case 0: {
            [self showBrowserForSimpleCaseWithIndex:indexPath.row];
        }
            break;
        case 1: {
            [self showBrowserForMixedCaseWithIndex:indexPath.row];
        }
            break;
        case 2: {
            [self showBrowserForSystemAlbumWithIndex:indexPath.row];
        }
            break;
    }
}

#pragma mark - getter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CGFloat padding = 5, cellLength = ([UIScreen mainScreen].bounds.size.width - padding * 2) / 3;
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.itemSize = CGSizeMake(cellLength, cellLength);
        layout.sectionInset = UIEdgeInsetsMake(padding, padding, padding, padding);
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - YBIB_HEIGHT_STATUSBAR - 40 - YBIB_HEIGHT_EXTRABOTTOM - 44) collectionViewLayout:layout];
        [_collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(MainImageCell.class) bundle:nil] forCellWithReuseIdentifier:kReuseIdentifierOfMainImageCell];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

- (UIButton *)clearButton {
    if (!_clearButton) {
        _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _clearButton.frame = CGRectMake(15, CGRectGetMaxY(self.collectionView.frame) + 7.5, 80, 25);
        [_clearButton setTitle:@"清理缓存" forState:UIControlStateNormal];
        _clearButton.titleLabel.font = [UIFont systemFontOfSize:15];
        _clearButton.backgroundColor = [UIColor orangeColor];
        _clearButton.layer.cornerRadius = 4;
        _clearButton.layer.masksToBounds = YES;
        [_clearButton addTarget:self action:@selector(clickClearButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clearButton;
}

- (UISegmentedControl *)segmentControl {
    if (!_segmentControl) {
        _segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"", @"", @""]];
        NSArray *arr = @[@"简单案例\nSimple case", @"混合案例\nMixed case", @"系统相册\nSystem album"];
        int idx = 0;
        for(UIView *subview in _segmentControl.subviews) {
            if([NSStringFromClass(subview.class) isEqualToString:@"UISegment"]) {
                for(UIView *segmentSubview in subview.subviews) {
                    if([NSStringFromClass(segmentSubview.class) isEqualToString:@"UISegmentLabel"]) {
                        UILabel *label = (id)segmentSubview;
                        label.numberOfLines = 2;
                        label.text = arr[idx++];
                        CGRect frame = label.frame;
                        frame.size = label.superview.frame.size;
                        label.frame = frame;
                    }
                }
            }
        }
        _segmentControl.frame = CGRectMake(0, 0, 200, 38);
        _segmentControl.selectedSegmentIndex = 1;
        [_segmentControl addTarget:self action:@selector(clickSegmentControl:) forControlEvents:UIControlEventValueChanged];
        [self clickSegmentControl:_segmentControl];
    }
    return _segmentControl;
}

#pragma mark - Photo

+ (NSArray *)getPHAssets {
    NSMutableArray *resultArray = [NSMutableArray array];
    PHFetchResult *smartAlbumsFetchResult0 = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    [smartAlbumsFetchResult0 enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAssetCollection  *_Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<PHAsset *> *assets = [self getAssetsInAssetCollection:collection];
        [resultArray addObjectsFromArray:assets];
    }];
    
    PHFetchResult *smartAlbumsFetchResult1 = [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:nil];
    [smartAlbumsFetchResult1 enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL *stop) {
        NSArray<PHAsset *> *assets = [self getAssetsInAssetCollection:collection];
        [resultArray addObjectsFromArray:assets];
    }];
    
    return resultArray;
}

+ (NSArray *)getAssetsInAssetCollection:(PHAssetCollection *)assetCollection {
    NSMutableArray<PHAsset *> *arr = [NSMutableArray array];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    [result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.mediaType == PHAssetMediaTypeImage) {
            [arr addObject:obj];
        } else if (obj.mediaType == PHAssetMediaTypeVideo) {
            [arr addObject:obj];
        }
    }];
    return arr;
}

@end
