Pod::Spec.new do |s|
  s.name         = "LlamaKit"
  s.version      = "0.1.0"
  s.summary      = "Collection of must-have functional Swift tools."
  s.description  = "Collection of must-have functional tools. Trying to be as lightweight as possible, hopefully providing a simple foundation that more advanced systems can build on. LlamaKit is very Cocoa-focused. It is designed to work with common Cocoa paradigms, use names that are understandable to Cocoa devs, integrate with Cocoa tools like GCD, and in general strive for a low-to-modest learning curve for devs familiar with ObjC and Swift rather than Haskell and ML."
  s.homepage     = "https://github.com/LlamaKit/LlamaKit"
  s.license      = "MIT"
  s.author             = { "Rob Napier" => "robnapier@gmail.com" }
  s.social_media_url   = "http://twitter.com/cocoaphony"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.source       = { :git => "https://github.com/LlamaKit/LlamaKit.git", :tag => "v0.1.0" }
  s.source_files  = "LlamaKit/*.swift"
end
