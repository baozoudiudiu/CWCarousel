Pod::Spec.new do |s|
  s.name         = "OC_CWCarousel"
  s.version      = "1.1.3"
  s.summary      = "banner. 无限滚动轮播图"
  s.homepage     = "https://github.com/baozoudiudiu/CWCarousel"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "baozoudiudiu" => "diudiu_WangChen@163.com" }
  s.source       = { :git => "https://github.com/baozoudiudiu/CWCarousel.git",
                     :tag => "#{s.version}" }
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.source_files = 'OC_CWCarousel/*'
  s.frameworks   = 'Foundation', 'UIKit'
end
