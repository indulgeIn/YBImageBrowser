# YBImageBrowser ( 2.0 )

![use](https://github.com/indulgeIn/YBImageBrowser/blob/master/OtherDocuments/ybib_st_use.gif)
![use](https://github.com/indulgeIn/YBImageBrowser/blob/master/OtherDocuments/ybib_st_image.PNG)
![use](https://github.com/indulgeIn/YBImageBrowser/blob/master/OtherDocuments/ybib_st_video.jpg)
![use](https://github.com/indulgeIn/YBImageBrowser/blob/master/OtherDocuments/ybib_st_sheetview.PNG)
![use](https://github.com/indulgeIn/YBImageBrowser/blob/master/OtherDocuments/ybib_st_custom.PNG)

# 相关链接 / Related link


* 博客正在码字


* [中文介绍](#中文介绍)
* [English Introduction](#english-introduction)



# 中文介绍


**iOS 图片浏览器（支持视频），功能强大，性能优越，轻松集成，易于拓展。**

关于版本的说明：2.x 版本全新升级，之前的代码仅保留 1.1.2 版本且不再维护，希望开发者朋友们升级到最新版本。



## 特性

- 支持 GIF，APNG，WebP 等本地和网络图像类型（由 YYImage、SDWebImage 提供支持）。
- 支持本地和网络视频。
- 支持系统相册图像和视频
- 支持高清图浏览。
- 支持屏幕旋转。
- 支持预加载提高用户体验。
- 支持数组或协议配置数据源，自由决定内存占用和交互性能的取舍。
- 支持数据重载。
- 支持文案更改，默认有英语和简体中文的适配。
- 支持业界流行的交互动效。
- 基于面向协议设计模式，轻松自定义 Cell、ToolBar、SheetView。
- 质量不错的代码细节和架构设计，易于拓展和维护。




## 安装

### CocoaPods

1. 在 Podfile 中添加 `pod 'YBImageBrowser'`。
2. 执行 `pod install` 或 `pod update`。
3. 导入 `<YBImageBrowser/YBImageBrowser.h>`。
4. 注意：如果你需要支持 WebP，可以在 Podfile 中添加 `pod 'YYImage/WebP'`。

若搜索不到库，可使用 `rm ~/Library/Caches/CocoaPods/search_index.json` 移除本地索引然后再执行安装，或者更新一下 CocoaPods 版本。

### 手动导入

1. 下载 YBImageBrowser 文件夹所有内容并且拖入你的工程中。
2. 链接以下 frameworks：
* SDWebImage 4.3.3
* YYImage
3. 导入 `YBImageBrowser.h`
4. 注意：如果你需要支持 WebP，可以在 Podfile 中添加 `pod 'YYImage/WebP'`，或者到手动下载 [YYImage 仓库](https://github.com/ibireme/YYImage) 的 webP 支持文件。




## 用法

`YBImageBrowser` 是图片浏览器的主体类，有两种方式为其赋值数据源：一种是直接设置 `dataSourceArray` 数组属性，一种设置 `dataSource` 代理属性实现协议方法。
数据源个体为 `id<YBImageBrowserCellDataProtocol>` 类型，框架默认实现了两个类：`YBImageBrowseCellData` (图片) 和 `YBVideoBrowseCellData` (视频)，你只需要初始化它们并且以数组或者代理的方式赋值给 `YBImageBrowser` 实例变量。


### 简易使用

```objc
// 图片
YBImageBrowseCellData *data0 = [YBImageBrowseCellData new];
data0.url = ...;
data.sourceObject = ...;    

// 视频
YBVideoBrowseCellData *data1 = [YBVideoBrowseCellData new];
data1.url = ...;
data1.sourceObject = ...;  

// 设置数据源数组并展示
YBImageBrowser *browser = [YBImageBrowser new];
browser.dataSourceArray = @[data0, data1];
browser.currentIndex = ...;
[browser show];
```

两种数据模型都有一个属性  `sourceObject`，该属性是该数据模型的对应的视图对象。举个例子，经典的朋友圈九宫格，`sourceObject` 可以是九宫格里面的九张图片，它的作用主要是做动效。


### 使用代理设置数据源

```objc
// 设置数据源代理并展示
YBImageBrowser *browser = [YBImageBrowser new];
browser.dataSource = self;
browser.currentIndex = index;
[browser show];

// 实现 <YBImageBrowserDataSource> 协议方法配置数据源
- (NSUInteger)yb_numberOfCellForImageBrowserView:(YBImageBrowserView *)imageBrowserView { 
    return ...; 
}
- (id<YBImageBrowserCellDataProtocol>)yb_imageBrowserView:(YBImageBrowserView *)imageBrowserView dataForCellAtIndex:(NSUInteger)index {
    YBImageBrowseCellData *data = [YBImageBrowseCellData new];
    data.url = ...;
    data.sourceObject = ...;
    return data;
}
```
更具体的用法请下载 Demo 查看。


### 内存占用和交互性能的取舍

通过设置数组配置数据源，图片浏览器会持有这些数据模型，这些数据模型会缓存数据处理结果，从而提高用户交互性能。在数据量较少的情况下，笔者推荐这种方式。

但是，图片浏览器持有大量的数据会增加内存的负担，特别是已经绘制完成的图像对象（UIImage）会占用较高的内存。所以在数据模型很多的情况下（比如相册浏览），可以设置代理实现协议方法来配置数据源，值得注意的是，在你的业务中最好不要持有这些数据模型，不然它们仍然不会释放造成内存负担。虽然这种方式可能会降低用户体验，但也是权宜之计。


### 关于缩略图（预览图）

`YBImageBrowseCellData` 有两个属性设置缩略图：`thumbImage` 和 `thumbUrl`。
`YBVideoBrowseCellData` 有一个属性设置缩略图：`firstFrame`。

数据模型若设置了 `sourceObject`，并且 `sourceObject` 是 `UIImageView` 类型的，那么组件会自动将该图片作为 `thumbImage`，所以这种情况不需要另外设置缩略图了。


### 关于预加载

`YBImageBrowseCellData` 和 `YBVideoBrowseCellData` 都有一个方法 `-preload` ，顾名思义就是预加载，若你设置图片或视频过后调用了该方法，会预先处理数据并且缓存下来，否则，数据会在界面展示的时候处理。这是一个对用户体验的优化，可以让用户更流畅的浏览内容，但该方法会增加 CPU 的负担（虽然基本是异步执行的），所以若数据模型过多慎用该方法。


### 图片处理的一些配置

当一张图片过大，组件会自动压缩显示，并且在放大的时候裁剪显示，这个纹理尺寸的临界值可以通过 `YBImageBrowseCellData` 的 `globalMaxTextureSize` 属性设置。

对于图片的缩放比例，组件会根据图片的分辨率自动计算，你也可以通过 `maxZoomScale` 属性显式的设置。


### 自定义文案（国际化）

组件中有一个单例，通过 `[YBIBCopywriter shareCopywriter]` 获取，组件内部的文案都是来自于这个实例变量，默认支持英语和简体中文，你可以更改暴露出来的所有文案属性，做更完整的语言国际化需求。


### 自定义工具栏（ToolBar）

组件提供了默认的工具栏，`YBImageBrowser` 下的 `defaultToolBar` ，它主要是显示页码，你可以通过它更改一些配置。

当然，若你有更高的自定义需求，可以设置 `YBImageBrowser` 下的 `toolBars` ，该属性是一个数组类型，数组元素遵循 `<YBImageBrowserToolBarProtocol>` 协议，默认情况下，该数组包含了 `defaultToolBar`。

所以，你只需要创建自己的工具栏并且实现 `<YBImageBrowserToolBarProtocol>` 协议，在协议方法中更新你的布局就行了（可以参考 `YBImageBrowserToolBar` 实现）。你不需要关心图层树的层级关系，只需要知道工具栏的层级高于浏览的图片和视频，组件会自动添加和隐藏工具栏。


### 自定义弹出表单（SheetView）

组件提供了默认的弹出表单，`YBImageBrowser` 下的 `defaultSheetView`，它主要是提供额外的操作，你可以通过它更改一些配置。

当然，若你有更高的自定义需求，可以设置 `YBImageBrowser` 下的 `sheetView` ，该属性遵循 `<YBImageBrowserSheetViewProtocol>` 协议，默认情况下，它就是 `defaultSheetView`。

所以，你只需要创建自己的弹出表单并且实现 `<YBImageBrowserSheetViewProtocol>` 协议，在协议方法中更新你的布局就行了（可以参考 `YBImageBrowserSheetView` 实现）。你不需要关心图层树的层级关系，只需要知道弹出表单的层级高于组件其它视图，组件会自动添加弹出表单，至于隐藏还是移除取决于你。


### 自定义浏览器 Cell

若图片浏览和视频播放的 Cell 还不能满足你的需求，可以定制你自己的 Cell，比如一个用于展示广告的 Cell。

在这之前，你需要实现一个遵循 `<YBImageBrowserCellDataProtocol>` 协议的数据类，一个遵循 `<YBImageBrowserCellProtocol>` 协议的 UICollectionViewCell 子类。参考 `YBImageBrowseCell/YBImageBrowseCellData` 或 `YBVideoBrowseCell/YBVideoBrowseCellData`，也可以下载 Demo，演示案例中实现了一个自定义的 Cell。

对于这两个协议，只需要实现 `@required` 协议方法就能成功构建，其它的方法可以自由选择实现。由于组件内置的两个 Cell 实现了比较复杂的交互和逻辑，所以协议方法看起来有些繁杂。








# English Introduction

**The iOS image browser (support video), powerful, superior performance, easy integration, easy to expand.**



## Features

- Support for local and network image types such as GIF, APNG, WebP (supported by YYImage and SDWebImage).
- Support for local and network video.
- Support for system album image and video.
- Support larger image browsing.
- Support for screen rotation.
- Support preloading to enhance user experience.
- Support configure data sources with arrays or protocols, freely determining trade-off between memory occupancy and interaction performance.
- Support data reload.
- Support for copywriter changes, with English and simplified Chinese adaptation by default.
- Support the industry popular interactive effect.
- Based on protocol oriented design patterns, easy custom 'Cell', 'ToolBar', and 'SheetView'.
- Good quality code details and architecture design, easy to expand and maintain.



## Installation

### CocoaPods

1. Add `pod 'YBImageBrowser'` to your Podfile.
2. Run `pod install` or `pod update`.
3. Import `<YBImageBrowser/YBImageBrowser.h>`
4. Notice: If you want to support WebP format, you may add `pod 'YYImage/WebP'` to your Podfile.

If the search failure, using ` rm ~ / Library/Caches/CocoaPods/search_index json ` remove local indexes and then perform the installation, or update CocoaPods version.

### Manually

1. Download all the files in the YBImageBrowser subdirectory.
2. Link with required frameworks:
* SDWebImage 4.3.3
* YYImage
3. Import `YBImageBrowser.h`
4. Notice: If you want to support WebP format, you may add `pod 'YYImage/WebP'` to your Podfile, or download webP support file manually from [YYImage 仓库](https://github.com/ibireme/YYImage).



## Usage

'YBImageBrowser'is the principal class of a image browser, and there are two ways to assign data sources to it: one is to set the 'dataSourceArray' array property directly, and the other is to set the 'dataSource' proxy and implementation protocol method.
The framework implements two classes by default: 'YBImageBrowseCellData'(image) and 'YBVideoBrowseCellData'(video), you just initialize them and assign them to the 'YBImageBrowser' instance variable in an array or proxy.


### Simple usage

```objc
// Image.
YBImageBrowseCellData *data0 = [YBImageBrowseCellData new];
data0.url = ...;
data.sourceObject = ...;    

// Video.
YBVideoBrowseCellData *data1 = [YBVideoBrowseCellData new];
data1.url = ...;
data1.sourceObject = ...;  

// Set the data source array and display it.
YBImageBrowser *browser = [YBImageBrowser new];
browser.dataSourceArray = @[data0, data1];
browser.currentIndex = ...;
[browser show];
```
Two kinds of data model has a property ` sourceObject `, this property is the view object of the corresponding data model, its main role is to do dynamic effect.


### Set up the data source proxy

```objc
// Set the data source proxy and show.
YBImageBrowser *browser = [YBImageBrowser new];
browser.dataSource = self;
browser.currentIndex = index;
[browser show];

// Implement <YBImageBrowserDataSource> protocol methods to configure data sources.
- (NSUInteger)yb_numberOfCellForImageBrowserView:(YBImageBrowserView *)imageBrowserView { 
return ...; 
}
- (id<YBImageBrowserCellDataProtocol>)yb_imageBrowserView:(YBImageBrowserView *)imageBrowserView dataForCellAtIndex:(NSUInteger)index {
YBImageBrowseCellData *data = [YBImageBrowseCellData new];
data.url = ...;
data.sourceObject = ...;
return data;
}
```

For more specific usage, please download the Demo.


### Trade-off between memory footprint and interaction performance

By setting up the array to configure data sources, 'Image browser' hold these data models, which cache data processing results and improve user interaction performance. I recommend this way if less data.

However, having a large amount of data in a image browser will increase the burden of memory, especially the rendered image objects (such as 'UIImage'). So in the case of a large number of data model (such as photo album browsing), you can set the proxy and implementation protocol methods to configure the data sources. It is important to note that it is best not to hold the data models in your business, otherwise they are still not release and increase the burden of memory. Although this approach may reduce user experience, it is also an expedient measure.


### About the thumbnail image

` YBImageBrowseCellData ` has two propertys set the thumbnail image: ` thumbImage ` and ` thumbUrl `.
`YBVideoBrowseCellData ` has an attribute set the thumbnail image: ` firstFrame `.

If the `sourceObject` is set in the data model and `sourceObject` is kind of  `UIImageView` , the component will set the image as a `thumbImage` automatically, so there is no need to set up another thumbnail image in this case.


### About preloading

Both `YBImageBrowseCellData` and `YBVideoBrowseCellData`  have a method `-preload`. If you call this method after setting up a picture or video, the data will be pre-processed and cached, otherwise, the data will be processed when the interface is displayed. This is an optimization of the user experience that allows users to browse content more smoothly, but this approach increases the CPU burden (albeit executed asynchronously) , so use this approach cautiously if the data model is too much.


### Some image configuration

When an image is too large, the component will compress to display automatically, and clip to display when enlarged, the critical value of the texture size can be set by the `globalMaxTextureSize` property of `YBImageBrowseCellData`.

For image scaling, the component will calculates automatically according to the resolution of the image, and you can also set it with the `maxZoomScale' property explicitly.


### Custom copywriter

There is a singleton in the component, which is retrieved by `[YBIBCopywriter shareCopywriter]'. The text inside the component comes from this instance variable. By default, English and Simplified Chinese are supported. You can change all the exposed text attributes to make more complete language internationalization requirements.


### Custom the 'ToolBar'

This component provides the default 'ToolBar', which is `defaultToolBar` in `YBImageBrowser`. It is used to display page numbers primarily, and you can change some configurations through it.

Of course, if you have higher customization requirements, you can set `toolBars` in `YBImageBrowser`, which is an array type whose elements follow the `<YBImageBrowserToolBarProtocol>` protocol, and by default contains `defaultToolBar`.

So you just need to create your own 'ToolBar' and implement the `<YBImageBrowserToolBarProtocol>` protocol and update your layout in the protocol method (see `YBImageBrowserToolBar` implementation). You don't need to care about layer relationships, just know that all the 'ToolBar' is higher than the browser's image and video, and the component adds and hides all the 'ToolBar' automatically.


### Custom the 'SheetView'

This component provides the default 'SheetView', which is `defaultSheetView` in `YBImageBrowser`. It is used to provide additional operations, and you can change some configurations through it.

Of course, if you have higher customization requirements, you can set `sheetView` in `YBImageBrowser`, `sheetView`  follow the `<YBImageBrowserSheetViewProtocol>` protocol, and by default it's `defaultSheetView`.

So you just need to create your own 'SheetView' and implement the `<YBImageBrowserSheetViewProtocol>` protocol and update your layout in the protocol method (see `YBImageBrowserSheetView` implementation). You don't need to care about layer relationships, just know that all the 'SheetView' is higher than all the layer of image browser, and the component adds the 'SheetView' automatically, as for concealment or removal, it depends on you.


### Custom 'Cell'

If the'Cell' for images and videos doesn't meet your needs, you can customize your own 'Cell', such as one for advertising.

Before you do this, you need to implement a data class that follows the `<YBImageBrowserCellDataProtocol>` protocol, and a UICollectionViewCell subclass that follows the `<YBImageBrowserCellProtocol>`. Referring to `YBImageBrowseCell/YBImageBrowseCellData` , or `YBVideoBrowseCell/YBVideoBrowseCellData`, you can also download Demo, which implements a custom 'Cell' in the demo case.

For these two protocols, only implement the `@required` protocol method can be successfully constructed, and other methods can be freely chosen to implement.







