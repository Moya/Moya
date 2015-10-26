Pod::Spec.new do |s|
  s.name         = "ReactiveMoya"
  s.version      = "4.0.3"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Moya/Moya.git", :tag => s.version }

  s.source_files = ["Moya/*swift", "Moya/Plugins/*swift", "Moya/ReactiveCore/*.swift", "Moya/ReactiveCocoa/*.swift"]
  s.dependency 'Alamofire', "~> 3.0"
  s.dependency "ReactiveCocoa", "= 4.0.0-alpha-3"
end
