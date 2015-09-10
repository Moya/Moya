Pod::Spec.new do |s|
  s.name         = "Moya"
  s.version      = "2.0.0"
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

  s.subspec "Core" do |ss|
    ss.source_files  = "Moya/*.swift"
    ss.dependency "Alamofire"
    ss.framework  = "Foundation"
  end

  s.subspec "ReactiveCore" do |ss|
    ss.source_files = "Moya/ReactiveCore/*.swift"
    ss.dependency "Moya/Core"
  end

  s.subspec "ReactiveCocoa" do |ss|
    ss.source_files = "Moya/ReactiveCocoa/*.swift"
    ss.dependency "Moya/ReactiveCore"
    ss.dependency "ReactiveCocoa"
  end

  s.subspec "RxSwift" do |ss|
    ss.source_files = "Moya/RxSwift/*.swift"
    ss.dependency "Moya/ReactiveCore"
    ss.dependency "RxSwift"
  end
end
