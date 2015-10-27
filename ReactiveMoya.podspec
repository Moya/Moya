Pod::Spec.new do |s|
  s.name         = "ReactiveMoya"
  s.version      = "4.1.0"
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.source       = { :git => "https://github.com/Moya/Moya.git", :tag => s.version }

  s.source_files = ["Moya/*swift", "Moya/Plugins/*swift", "Moya/ReactiveCore/*.swift", "Moya/ReactiveCocoa/*.swift"]
  s.dependency 'Alamofire', "~> 3.0"
  s.dependency "ReactiveCocoa", "~> 4.0-alpha.1"
end
