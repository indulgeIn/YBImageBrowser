# YBImageBrowser
iOS图片浏览器（功能强大，性能优越）==   image browser for iOS (powerful, superior performance)

<img src="https://github.com/indulgeIn/YBImageBrowser/blob/master/OtherDocuments/YBImageBrowserShowGif.gif">



# 中文说明




## 安装

### 使用 cocoapods

**pod 'YBImageBrowser', '~> 1.0.4'**    

注意：请不要使用 1.0.4 之前的版本；若搜索不到库，可使用`rm ~/Library/Caches/CocoaPods/search_index.json`移除本地索引然后再执行安装，或者更新一下 cocoapods 版本。

### 手动导入

直接将该 Demo 的 `YBImageBrowser` 文件夹拖入你的工程中，并在你的 Podfile 里面添加：
<pre><code>pod 'SDWebImage', '~> 4.3.3'
pod 'FLAnimatedImage', '~> 1.0.12'
</code></pre>



## 用法

框架设计为每一个图片都是一个`YBImageBrowserModel`的实例模型，使用时只需要配置足够的`YBImageBrowserModel`实例，然后用数组或者实现代理的方式传给图片浏览器`YBImageBrowser`，然后调用`show`方法展示出来。注意本文会有一些伪代码，具体可以看框架API，有详尽的注释，大部分的自定义配置都是在`YBImageBrowser.h`文件下。

### 最简易的使用：
<pre><code>//创建数据源
YBImageBrowserModel *model0 = [YBImageBrowserModel new];
[model0 setImageWithFileName:imageName fileType:imageType];
model0.sourceImageView = ...
...

//创建图片浏览器
YBImageBrowser *browser = [YBImageBrowser new];
browser.dataArray = @[model0, ...];
browser.currentIndex = ...
[browser show];
</code></pre>

值得注意的是，`YBImageBrowserModel`的`sourceImageView`是当前图片对应的`UIImageView`，这是为了在图片浏览器的入场或出场时有一个移动(move)的动画效果；
`YBImageBrowser`的`currentIndex`属性也是比较重要的，告知图片浏览器优先显示的图片下标。

### 使用代理配置数据源

除了使用数组直接赋值的方式配置数据源，框架还支持使用代理配置，用过`UITableView`的朋友应该很容易理解：

<pre><code>YBImageBrowser *browser = [YBImageBrowser new];
//设置数据源代理
browser.dataSource = self;
browser.currentIndex = ...
[browser show];
</code></pre>

然后通过实现下列的方法完成数据源的配置（具体意义请看框架API）：

<pre><code>- (UIImageView * _Nullable)imageViewOfTouchForImageBrowser:(YBImageBrowser *)imageBrowser;
- (NSInteger)numberInYBImageBrowser:(YBImageBrowser *)imageBrowser;
- (YBImageBrowserModel *)yBImageBrowser:(YBImageBrowser *)imageBrowser modelForCellAtIndex:(NSInteger)index;
</code></pre>

### 功能栏配置

在长按或者点击右上角时，有功能栏弹出（默认只有一个保存功能，所以没有功能栏弹出效果），你可以通过`fuctionDataArray`属性自定义功能栏的数据，还有其他的配置，详情在`YBImageBrowser.h`中可见，写得很清楚。框架默认实现了保存功能，你可以把`fuctionDataArray`属性置空来取消所有功能。

### 动画配置

默认会有一个平滑移动入场和出场动画，向下拖拽时的动画效果是模仿微信的，因为我认为微信的图片浏览器是做得最棒的；你可以通过`YBImageBrowser.h`中的`inAnimation`和`outAnimation`属性配置入场和出场的动画类型，目前支持得不多，后期迭代考虑集成更多的动效；还有其它比如转场动画持续时间、拖拽动效的取消、页间距等属性可以自定义配置。

### 屏幕旋转

屏幕旋转支持的方向可以自定义，通过`yb_supportedInterfaceOrientations`属性来
