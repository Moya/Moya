Pod::Spec.new do |s|
  s.name         = "Moya"
  s.version      = "2.4.1"
  s.summary      = "Network abstraction layer written in Swift"
  s.description  = <<-EOS
  Moya abstracts network commands using Swift Generics to provide developers
  with more compile-time confidence.

  ReactiveCocoa and RxSwift extensions exist as well. Instructions for installation
  are in [the README](https://github.com/Moya/Moya).
  EOS
  s.homepage     = "https://github.com/Moya/Moya"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Ash Furrow" => "ash@ashfurrow.com" }
  s.social_media_url   = "http://twitter.com/ashfurrow"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Moya/Moya.git", :tag => s.version }
  s.default_subspec = "Core"

  s.subspec "Core" do |ss|
    ss.source_files  = "Moya/*.swift"
    ss.dependency "Alamofire", "~> 2.0"
    ss.framework  = "Foundation"
  end

  s.subspec "ReactiveCore" do |ss|
    ss.source_files = "Moya/ReactiveCore/*.swift"
    ss.dependency "Moya/Core"
  end

  s.subspec "ReactiveCocoa" do |ss|
    ss.source_files = "Moya/ReactiveCocoa/*.swift"
    ss.dependency "Moya/ReactiveCore"
    ss.dependency "ReactiveCocoa", "~> 4.0-alpha.1"
  end

  s.subspec "RxSwift" do |ss|
    ss.source_files = "Moya/RxSwift/*.swift"
    ss.dependency "Moya/ReactiveCore"
    ss.dependency "RxSwift", "~> 2.0.0-alpha"
  end
end
