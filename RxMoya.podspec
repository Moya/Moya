Pod::Spec.new do |s|
  s.name         = "RxMoya"
  s.version      = "4.0.3"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Moya/Moya.git", :tag => s.version }

  s.source_files = ["Source/*swift", "Source/Plugins/*swift", "Source/ReactiveCore/*.swift", "Source/RxSwift/*.swift"]
  s.dependency "RxSwift", "~> 2.0.0-alpha"
end
