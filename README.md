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

框架设计为每一个图片都是一个`YBImageBrowserModel`的实例模型，使用时只需要配置足够的`YBImageBrowserModel`实例，然后用数组或者实现代理的方式传给图片浏览器`YBImageBrowser`，然后调用`show`方法展示出来。

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

当然，除了使用数组直接赋值的方式配置数据源，框架还支持使用代理配置，用过`UITableView`的朋友应该很容易理解：

<pre><code>YBImageBrowser *browser = [YBImageBrowser new];
//设置数据源代理
browser.dataSource = self;
browser.currentIndex = ...
[browser show];
</code></pre>

然后通过实现下列的方法完成数据源的配置：

<pre><code>@protocol YBImageBrowserDataSource <NSObject>
@required

/**
 返回点击的那个 UIImageView（用于做 YBImageBrowserAnimationMove 类型动效）

 @param imageBrowser 当前图片浏览器
 @return 点击的图片视图
 */
- (UIImageView * _Nullable)imageViewOfTouchForImageBrowser:(YBImageBrowser *)imageBrowser;

/**
 配置图片的数量

 @param imageBrowser 当前图片浏览器
 @return 图片数量
 */
- (NSInteger)numberInYBImageBrowser:(YBImageBrowser *)imageBrowser;

/**
 返回当前 index 图片对应的数据模型

 @param imageBrowser 当前图片浏览器
 @param index 当前下标
 @return 数据模型
 */
- (YBImageBrowserModel *)yBImageBrowser:(YBImageBrowser *)imageBrowser modelForCellAtIndex:(NSInteger)index;

@end
</code></pre>

