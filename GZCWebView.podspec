Pod::Spec.new do |s|
  s.name         = "GZCWebView"
  s.version      = "1.0.0"
  s.summary      = "GZCWebView desc"

  s.homepage     = "https://github.com/gzhongcheng"
  s.license         = { type: 'MIT', file: 'LICENSE' }

  s.author       = { "gzhongcheng" => "gzhongcheng@qq.com" }

  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/gzhongcheng/GZCWebView.git",:tag => s.version}
  s.source_files = "GZCWebView/*.{h,m}"
  s.requires_arc = true
  s.dependency 'SDAutoLayout'
  s.dependency 'UIView+Capture'
end 
