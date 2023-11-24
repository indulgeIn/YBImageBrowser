platform:ios, '12.0'
target ‘YBImageBrowserDemo’ do
use_frameworks!


pod 'SDWebImage', '5.18.5'
pod 'SDWebImageWebPCoder'
#pod 'SDWebImage/WebP'
# 兼容新系统的问题
pod 'YYImage', :git => 'https://github.com/QiuYeHong90/YYImage.git'
pod 'YYImage/WebP', :git => 'https://github.com/QiuYeHong90/YYImage.git'
pod 'LookinServer', :configurations => ['Debug']

end
# 兼容m1 电脑模拟器
post_install do |pi|
    pi.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
    pi.pods_project.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
    end
end
