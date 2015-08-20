Pod::Spec.new do |s|
  s.name         = "ReactiveCocoa"
  s.version      = "4-beta"
  s.summary      = "A framework for composing and transforming streams of values"

  s.platform = :ios
  s.description  = <<-DESC
                   ReactiveCocoa (RAC) is an Objective-C framework for Functional Reactive Programming. It provides APIs for composing and transforming streams of values.

                   DESC

  s.homepage     = "https://github.com/ReactiveCocoa/ReactiveCocoa"
  s.license      = "MIT"
  s.authors      = { "Jérémie Girault" => "jeremie.girault@gmail.com" }
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.source       = { :git => "https://github.com/ReactiveCocoa/ReactiveCocoa.git" }

  s.subspec "no-arc" do |sp|
    sp.frameworks = 'Foundation'
    sp.source_files  = "ReactiveCocoa/Objective-C/RACObjCRuntime.{h,m}"
    sp.requires_arc = false
  end

  s.subspec "Core" do |sp|
    sp.frameworks = 'Foundation'
    sp.source_files  = "ReactiveCocoa/Objective-C/RACObjCRuntime.{h,m}", "ReactiveCocoa/**/*.{d,h,m,swift}" 
    sp.exclude_files = "**/ReactiveCocoa.h", "ReactiveCocoa/**/*{RACObjCRuntime,AppKit,NSControl,NSText,NSTable,UIActionSheet,UIAlertView,UIBarButtonItem,UIButton,UICollectionReusableView,UIControl,UIDatePicker,UIGestureRecognizer,UIImagePicker,UIRefreshControl,UISegmentedControl,UISlider,UIStepper,UISwitch,UITableViewCell,UITableViewHeaderFooterView,UIText,MK}*"
    sp.header_dir = "ReactiveCocoa"
    sp.private_header_files = "**/*Private.h", "**/*EXTRuntimeExtensions.h", "**/RACEmpty*.h"

    sp.dependency 'ReactiveCocoa/no-arc'
  end

  s.subspec "UI" do |sp|
    sp.ios.frameworks = 'UIKit'
    sp.osx.frameworks = 'AppKit'

    sp.ios.source_files = "ReactiveCocoa/**/*{UIActionSheet,UIAlertView,UIBarButtonItem,UIButton,UICollectionReusableView,UIControl,UIDatePicker,UIGestureRecognizer,UIImagePicker,UIRefreshControl,UISegmentedControl,UISlider,UIStepper,UISwitch,UITableViewCell,UITableViewHeaderFooterView,UIText,MK}*"
    sp.osx.source_files = "ReactiveCocoa/**/*{AppKit,NSControl,NSText,NSTable}*"

    sp.dependency 'ReactiveCocoa/Core'
  end

  s.default_subspec = "UI"

  s.dependency 'Result', '~> 0.6-beta.1'
end
