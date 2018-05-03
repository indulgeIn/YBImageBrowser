# YBImageBrowser (The latest version: 1.0.6)

README 主要讲解用户可以配置的 API，设计思路及更多技术原理可以看笔者的简书文章：https://www.jianshu.com/p/bff0c6d89814

<img src="https://github.com/indulgeIn/YBImageBrowser/blob/master/OtherDocuments/YBImageBrowserShowGif.gif">



# 中文说明




## 安装

### 使用 cocoapods

**pod 'YBImageBrowser'**    

注意：请尽量使用 1.0.6 及其之后的版本；若搜索不到库，可使用`rm ~/Library/Caches/CocoaPods/search_index.json`移除本地索引然后再执行安装，或者更新一下 cocoapods 版本。

### 手动导入

直接将该 Demo 的 `YBImageBrowser` 文件夹拖入你的工程中，并在你的 Podfile 里面添加：
<pre><code>pod 'SDWebImage', '~> 4.3.3'
pod 'FLAnimatedImage', '~> 1.0.12'
</code></pre>



## 用法

框架设计为每一个图片都是一个`YBImageBrowserModel`的实例模型，使用时只需要配置足够的`YBImageBrowserModel`实例，然后用数组或者实现代理的方式传给图片浏览器`YBImageBrowser`，然后调用`show`方法展示出来。注意本文会有一些伪代码，具体可以看框架API，有详尽的注释，大部分的自定义配置都是在`YBImageBrowser.h`文件和`YBImageBrowserModel.h`文件下，一个倾向于整体配置，一个倾向于单独配置。

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

### 内存优化配置

对于本地图片，使用`[UIImage imageNamed:name]`方式设置图片系统会自动缓存图片，若你使用的本地图片过大会造成大量的内存开销，所以建议使用文件读取的方式拿到图片，可以通过`YBImageBrowserModel`实例方法`setImageWithFileName:fileType:`方便配置。若是本地的 gif，请配置`gifName`属性，但是不要带后缀，组件会自动转换成需要的类型。

对于网络图片，使用的是`SDWebImage`框架，对于它的下载和缓存你可以通过`YBImageBrowser`下的`downloaderShouldDecompressImages`属性设置是否解压并且缓存到内存，若你要展示的图片都是高清图片，那建议你将该属性置为NO。

对于超清大图，组件内部会异步压缩和异步裁剪来减小内存的开销，若你的业务界面非常敏感，可以通过`YBImageBrowser`下的`maxDisplaySize`属性配置最大支持pt，超过这个限度，组件就要做相应的优化了。

### 下载体验优化

对于网络图片，通常情况下直接给`YBImageBrowserModel`的属性`url`赋值就行了，若你要追求更好的浏览体验，可以使用`YBImageBrowserModel`的方法`setUrlWithDownloadInAdvance:`实现预下载。

### 缩略图

`YBImageBrowserModel.h`下有一个属性：

`@property (nonatomic, strong, nullable) YBImageBrowserModel *previewModel;`

它同样是`YBImageBrowserModel`类型的，因为你想展现的缩略图可以只是知道一个`url`，所以这里索性用同一个类型表示它。当然，你不需担心缩略图是否下载或者是否分辨率过大，组件内部有足够的容错和优化机制。

### 功能栏配置

在长按或者点击右上角时，有功能栏弹出（默认只有一个保存功能，所以没有功能栏弹出效果），你可以通过`fuctionDataArray`属性自定义功能栏的数据，还有其他的配置，详情在`YBImageBrowser.h`中可见，写得很清楚。框架默认实现了保存功能，你可以把`fuctionDataArray`属性置空来取消所有功能。

### 动画配置

默认会有一个平滑移动入场和出场动画，向下拖拽时的动画效果是模仿微信的，因为我认为微信的图片浏览器是做得最棒的；你可以通过`YBImageBrowser.h`中的`inAnimation`和`outAnimation`属性配置入场和出场的动画类型，目前支持得不多，后期迭代考虑集成更多的动效；还有其它比如转场动画持续时间、拖拽动效的取消、页间距等属性可以自定义配置。

### 屏幕旋转

屏幕旋转支持的方向可以自定义，通过`yb_supportedInterfaceOrientations`属性来设置。值得注意的是，目前本框架还不支持自动旋转，意味着
在目标工程的

`general -> deployment info -> Device Orientation`

中的配置，将直接影响组件的实际支持旋转方向。

### 图片缩放

图片缩放方面，组件会自动计算，同时做了一定的盈余，保证在放大到最大可显示px时还能继续放大一部分保证看的更清楚。若你不喜欢组件做的这些优化，可以通过`autoCountMaximumZoomScale`来取消该功能；还可以选择填充的方式，目前支持宽度抵满方式和完全显示方式。

### 文案撰写者

组件加入了一个实例：

`@property (nonatomic, strong) YBImageBrowserCopywriter *copywriter;`

笔者叫它文案撰写者，你可以对其属性赋值，来替换默认的一些文案（国际化时用起来比较方便）。

### 状态栏的处理

状态栏组件会自动判断你在`info.plist`里的配置，所有不需担心兼容性问题，方便使用，不管你是何种配置，都可以通过`showStatusBar`属性来显示或者隐藏状态栏。

### 更换图片下载库

若你想更换`SDWebImage`库为其他图片库，可以更改`NSBundle+YBImageBrowser`延展，所有与`SDWebImage`有关的使用都在里面，替换并不困难。



