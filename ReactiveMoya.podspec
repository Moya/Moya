Pod::Spec.new do |s|
  s.name         = "ReactiveMoya"
  s.version      = "2.2.0"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Moya/Moya.git", :tag => s.version }

  s.source_files = ["Moya/ReactiveCore/*.swift", "Moya/ReactiveCocoa/*.swift"]
  s.dependency "Moya"
  s.dependency "ReactiveCocoa"
end
