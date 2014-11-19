Pod::Spec.new do |s|
  s.name         = "Nimble"
  s.version      = "0.0.1"
  s.summary      = "A Matcher Framework for Swift and Objective-C"
  s.description  = <<-DESC
                   Use Nimble to express the expected outcomes of Swift or Objective-C expressions. Inspired by Cedar.
                   DESC
  s.homepage     = "https://github.com/Quick/Nimble"
  s.license      = { :type => "Apache 2.0", :file => "LICENSE.md" }
  s.author             = { "modocache" => "modocache@gmail.com" }
  s.social_media_url   = "http://twitter.com/modocache"
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.7"
  s.source       = { :git => "https://github.com/Quick/Nimble.git", :commit => "81a2d8a63083ae6512d40f7a02d5e075e57be317" }

  s.source_files  = "Nimble", "Nimble/**/*.{swift,h,m}"
  s.framework = "XCTest"
end
