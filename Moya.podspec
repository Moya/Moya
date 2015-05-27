Pod::Spec.new do |s|
  s.name         = "Moya"
  s.version      = "1.0.0"
  s.summary      = "Network abstraction layer written in Swift"
  s.description  = <<-EOS
  Moya abstracts network commands using Swift Generics to provide developers 
  with more compile-time confidence. 

  A ReactiveCocoa extension exists as well. Instructions for its installation
  are in [the README](https://github.com/ashfurrow/Moya).
  EOS
  s.homepage     = "https://github.com/AshFurrow/Moya"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Ash Furrow" => "ash@ashfurrow.com" }
  s.social_media_url   = "http://twitter.com/ashfurrow"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/ashfurrow/Moya.git", :tag => s.version }
  s.default_subspec = "Core"
  s.requires_arc = true

  s.subspec "Core" do |ss|
    ss.source_files  = "Moya.swift", "Endpoint.swift"
    ss.dependency "Alamofire", "~> 1.2.0"
    ss.framework  = "Foundation"
  end

  s.subspec "Reactive" do |ss|
    ss.source_files = "Moya+ReactiveCocoa.swift", "RACSignal+Moya.swift"
    ss.dependency "Moya/Core"
    ss.dependency "ReactiveCocoa", "3.0-beta.6"
  end
end
