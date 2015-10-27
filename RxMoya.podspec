Pod::Spec.new do |s|
  s.name         = "RxMoya"
  s.version      = "4.1.0"
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.source       = { :git => "https://github.com/Moya/Moya.git", :tag => s.version }

  s.source_files = ["Moya/*swift", "Moya/Plugins/*swift", "Moya/ReactiveCore/*.swift", "Moya/RxSwift/*.swift"]
  s.dependency "RxSwift", "~> 2.0.0-alpha"
end
