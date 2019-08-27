

Pod::Spec.new do |s|


  s.name         = "YBImageBrowser"

  s.version      = "3.0.4"

  s.summary      = "iOS image browser / iOS 图片浏览器"

  s.description  = <<-DESC
  					iOS 图片浏览器，功能强大，易于拓展，极致的性能优化和严格的内存控制让其运行更加的流畅和稳健。
                   DESC

  s.homepage     = "https://github.com/indulgeIn"

  s.license      = "MIT"

  s.author       = { "杨波" => "1106355439@qq.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/indulgeIn/YBImageBrowser.git", :tag => "#{s.version}" }

  s.requires_arc = true

  s.default_subspec = "Core"

  s.subspec "SD" do |sd|
    sd.source_files = "YBImageBrowser/WebImageMediator/*.{h,m}"
    sd.dependency 'SDWebImage', '>= 5.0.0'
  end

  s.subspec "Core" do |core|
    core.source_files   = "YBImageBrowser/**/*.{h,m}"
    core.exclude_files  = "YBImageBrowser/WebImageMediator/*.{h,m}"
    core.resources      = "YBImageBrowser/YBImageBrowser.bundle"
    core.dependency 'YBImageBrowser/SD'
    core.dependency 'YYImage'
  end
  s.subspec "NOSD" do |core|
    core.source_files   = "YBImageBrowser/**/*.{h,m}"
    core.exclude_files  = "YBImageBrowser/WebImageMediator/*.{h,m}"
    core.resources      = "YBImageBrowser/YBImageBrowser.bundle"
    core.dependency 'YYImage'
  end

  s.subspec "Video" do |video|
    video.source_files = "Video/*.{h,m}"
    video.resources    = "Video/YBImageBrowserVideo.bundle"
    video.dependency 'YBImageBrowser/Core'
  end
  s.subspec "Video/NOSD" do |video|
    video.source_files = "Video/*.{h,m}"
    video.resources    = "Video/YBImageBrowserVideo.bundle"
    video.dependency 'YBImageBrowser/NOSD'
  end

end
