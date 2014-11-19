Pod::Spec.new do |s|
  s.name         = "Moya"
  s.version      = "0.5"
  s.summary      = "Network abstraction layer written in Swift"
  s.homepage     = "https://github.com/AshFurrow/Moya"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Ash Furrow" => "ash@ashfurrow.com" }
  s.social_media_url   = "http://twitter.com/ashfurrow"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/AshFurrow/Moya.git", :tag => "0.5" }
  s.default_subspec = "Core"

  s.subspec "Core" do |ss|
    ss.source_files  = "Moya.swift", "Endpoint.swift"
    ss.dependency "Alamofire"
    ss.framework  = "Foundation"
  end

  s.subspec "Reactive" do |ss|
    ss.source_files = "Moya+ReactiveCocoa.swift", "RACSignal+Moya.swift"
    ss.dependency "Moya/Core"
    ss.dependency "ReactiveCocoa"
  end
end
