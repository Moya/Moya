Pod::Spec.new do |s|
  s.name         = "RxMoya"
  s.version      = "2.1.0"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Moya/Moya.git", :tag => s.version }

  s.source_files = ["Moya/ReactiveCore/*.swift", "Moya/RxSwift/*.swift"]
  s.dependency "Moya"
  s.dependency "RxSwift"
end
