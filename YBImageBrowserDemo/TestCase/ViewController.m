//
//  ViewController.m
//  YBImageBrowserDemo
//
//  Created by 杨少 on 2018/4/10.
//  Copyright © 2018年 杨波. All rights reserved.
//

#import "ViewController.h"
#import "YBImageBrowser.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define CELLSIZE CGSizeMake(YB_SCREEN_WIDTH/3, (YB_SCREEN_WIDTH/3))
static int tagOfImageOfCell = 100;
static NSString * const kReuseIdentifierOfCell = @"UICollectionViewCell";

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray *dataArray0;
@property (nonatomic, copy) NSArray *dataArray1;

@end

@implementation ViewController

#pragma mark 图片浏览器使用案例 (image brower use case)

- (void)showWithTouchIndexPath:(NSIndexPath *)indexPath {
    
    //配置数据源（图片浏览器每一张图片对应一个 YBImageBrowserModel 实例）
    NSMutableArray *tempArr = [NSMutableArray array];
    for (NSString *str in self.dataArray0) {
        YBImageBrowserModel *model = [YBImageBrowserModel new];
        [model setImageWithFileName:str fileType:@"jpeg"];
        model.sourceImageView = [self getImageViewOfCellByIndexPath:indexPath];
        [tempArr addObject:model];
    }
    
    //创建图片浏览器（注意：更多功能请看 YBImageBrowser.h 文件或者 github readme）
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataArray = tempArr;
    browser.currentIndex = indexPath.row;
    browser.inAnimation = YBImageBrowserAnimationMove;
    browser.outAnimation = YBImageBrowserAnimationMove;
    
    //展示
    [browser show];
    
}







#pragma mark tool
- (UIImageView *)getImageViewOfCellByIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell) return nil;
    return [cell.contentView viewWithTag:tagOfImageOfCell];
}

#pragma mark life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.collectionView];
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return self.dataArray0.count;
    }
    return self.dataArray1.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifierOfCell forIndexPath:indexPath];
    FLAnimatedImageView *imgView = [cell.contentView viewWithTag:tagOfImageOfCell];
    if (!imgView) {
        imgView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(0, 0, CELLSIZE.width, CELLSIZE.height)];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.layer.masksToBounds = YES;
        imgView.tag = tagOfImageOfCell;
        [cell.contentView addSubview:imgView];
    }
    if (indexPath.section == 0) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:self.dataArray0[indexPath.row] ofType:@"jpeg"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        imgView.image = [UIImage imageWithData:data];
    } else {
        [imgView sd_setImageWithURL:self.dataArray1[indexPath.row]];
    }
    return cell;
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self showWithTouchIndexPath:indexPath];
}

#pragma mark getter
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.itemSize = CELLSIZE;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.sectionInset = UIEdgeInsetsZero;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, YB_SCREEN_WIDTH, YB_SCREEN_HEIGHT - 40) collectionViewLayout:layout];
        [_collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:kReuseIdentifierOfCell];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}
- (NSArray *)dataArray0 {
    if (!_dataArray0) {
        _dataArray0 = @[@"localImage0", @"localImage1", @"localImage2", @"localImage3", @"localImage4", @"localImage5", @"localImage6", @"localImage7", @"localImage8"];
    }
    return _dataArray0;
}
- (NSArray *)dataArray1 {
    if (!_dataArray1) {
        _dataArray1 = @[];
    }
    return _dataArray1;
}

#pragma mark button event
- (IBAction)clickClearButton:(id)sender {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
}

#pragma mark device orientation
- (BOOL)shouldAutorotate {
    return YES;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
