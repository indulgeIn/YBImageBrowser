# YBImageBrowser 

[![CocoaPods](https://img.shields.io/cocoapods/v/YBImageBrowser.svg)](https://cocoapods.org/pods/YBImageBrowser)&nbsp;
[![CocoaPods](https://img.shields.io/cocoapods/p/YBImageBrowser.svg)](https://github.com/indulgeIn/YBImageBrowser)&nbsp;
[![License](https://img.shields.io/github/license/indulgeIn/YBImageBrowser.svg)](https://github.com/indulgeIn/YBImageBrowser)&nbsp;

**iOS 图片浏览器，功能强大，易于拓展，极致的性能优化和严格的内存控制让其运行更加的流畅和稳健。**

**原理博客: TODO**

## 关于 3.x 版本

为了彻底解决 2.x 版本的设计缺陷和代码漏洞，特花费大量业余时间进行了 3.x 深度重构，所以没办法做到完全的向下兼容，希望社区朋友们能体谅，根据情况进行版本迁移。
3.x 版本有着更科学的架构，更极致的性能提升，更严格的内存控制，使用起来会更得心应手，也便于将来的迭代优化。

**使用 2.x 版本请切换到 store_2.x 分支。**


## 预览

[](https://github.com/indulgeIn/YBImageBrowser/blob/master/Images/preview.gif)



## 特性

- 支持 GIF，APNG，WebP 等本地和网络图片类型（由 YYImage、SDWebImage 提供支持）。
- 支持系统相册图片和视频。
- 支持简单的视频播放。
- 支持高清图浏览。
- 支持图片预处理（比如添加水印）。
- 支持根据图片的大小判断是否需要预先解码（精确控制内存）。
- 支持图片压缩、裁剪的界限设定。
- 支持修改下载图片的 NSURLRequest。
- 支持主动旋转或跟随控制器旋转。
- 支持自定义图标。
- 支持自定义 Toast/Loading。
- 支持自定义文案（默认提供中文和英文）。
- 支持自定义工具视图（比如查看原图功能）。
- 支持自定义 Cell（比如添加一个广告模块）。
- 支持添加到其它父视图上使用（比如加到控制器上）。
- 支持转场动效、图片布局等深度定制。
- 支持数据重载、局部更新。
- 支持低粒度的内存控制和性能调优。
- 极致的性能优化和严格的内存控制让其运行更加的流畅和稳健。

## 安装

TODO

### CocoaPods

1. 在 Podfile 中添加 `pod 'YBImageBrowser'`。
2. 执行 `pod install` 或 `pod update`。
3. 导入 `<YBImageBrowser/YBImageBrowser.h>`。
4. 注意：如果你需要支持 WebP，可以在 Podfile 中添加 `pod 'YYImage/WebP'`。

若搜索不到库，可使用 `rm ~/Library/Caches/CocoaPods/search_index.json` 移除本地索引然后再执行安装，或者更新一下 CocoaPods 版本。

### 手动导入

1. 下载 YBImageBrowser 文件夹所有内容并且拖入你的工程中。
2. 链接以下 frameworks：
* SDWebImage
* YYImage
3. 导入 `YBImageBrowser.h`
4. 注意：如果你需要支持 WebP，可以在 Podfile 中添加 `pod 'YYImage/WebP'`，或者到手动下载 [YYImage 仓库](https://github.com/ibireme/YYImage) 的 webP 支持文件。




## 用法

初始化`YBImageBrowser`并且赋值数据源`id<YBIBDataProtocol>`，默认提供`YBIBImageData` (图片) 和`YBIBVideoData` (视频) 两种数据源。

图片处理是组件的核心，笔者精力有限，视频播放做得很轻量，若有更高的要求最好是自定义 Cell，望体谅。

Demo 中提供了很多示例代码，演示较复杂的拓展方式，所以若需要深度定制最好是下载 Demo 查看。


### 基本使用

```
// 本地图片
YBIBImageData *data0 = [YBIBImageData new];
data0.imageName = ...;
data0.projectiveView = ...;

// 网络图片
YBIBImageData *data1 = [YBIBImageData new];
data1.imageURL = ...;
data1.projectiveView = ...;

// 视频
YBIBVideoData *data2 = [YBIBVideoData new];
data2.videoURL = ...;
data2.projectiveView = ...;

YBImageBrowser *browser = [YBImageBrowser new];
browser.dataSourceArray = @[data0, data1, data2];
browser.currentPage = ...;
[browser show];
```


### 设置支持的旋转方向

当图片浏览器依托的 UIViewController 仅支持一个方向：

这种情况通过`YBImageBrowser.new.supportedOrientations`设置图片浏览器支持的旋转方向。

否则：

上面的属性将失效，图片浏览器会跟随控制器的旋转而旋转，由于各种原因这种情况的旋转过渡有瑕疵，建议不使用这种方式。


### 自定义图标

修改`YBIBIconManager.sharedManager`实例的属性。


### 自定义文案

修改`YBIBCopywriter.sharedCopywriter`实例的属性。


### 自定义 Toast / Loading

实现`YBIBAuxiliaryViewHandler`协议，并且赋值给`YBImageBrowser.new.auxiliaryViewHandler`属性，可参考和协议同名的默认实现类。


### 自定义工具视图（ToolView）

默认实现的`YBImageBrowser.new.defaultToolViewHandler`处理器可以做一些属性配置，当满足不了业务需求时，最好是进行自定义，参考默认实现或 Demo 中“查看原图”功能实现。

定义一个或多个类实现`YBIBToolViewHandler`协议，并且装入`YBImageBrowser.new.toolViewHandlers`数组属性。建议使用一个中介者来实现这个协议，然后所有的工具视图都由这个中介者来管理，当然也可以让每一个自定义的工具 UIView 都实现`YBIBToolViewHandler`协议，请根据具体需求取舍。


### 自定义 Cell

当默认提供的`YBIBImageData` (图片) 和`YBIBVideoData` (视频) 满足不了需求时，可自定义拓展 Cell，参考默认实现或 Demo 中的示例代码。

定义一个实现`YBIBCellProtocol`协议的`UICollectionViewCell`类和一个实现`YBIBDataProtocol`协议的数据类，当要求不高时实现必选协议方法就能跑起来了，若对交互有要求就相对比较复杂，最好是参考默认的交互动效实现。

