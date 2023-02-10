# xcodebuild often ends with error code 65 and needs to be restarted.
# This function will re-run a command up to three times if it yeilds a 65 exit code.

def moya_project
  return 'Moya.xcodeproj'
end

def configuration
  return 'Debug'
end

def targets
  return [
    :macos,
    :tvos,
    :ios
  ]
end

def schemes
  return {
    ios: 'Moya',
    macos: 'Moya',
    tvos: 'Moya'
  }
end

def sdks
  return {
    ios: 'iphonesimulator',
    macos: 'macosx',
    tvos: 'appletvsimulator'
  }
end

def devices
  return {
    ios: "OS=#{device_os[:ios]},name=#{device_names[:ios]}",
    macos: "platform=macOS,arch=#{`uname -m | tr -d '\n'`}",
    tvos: "OS=#{device_os[:tvos]},name=#{device_names[:tvos]}"
  }
end

def device_names
  return {
    ios: "iPhone SE (3rd generation)",
    tvos: "Apple TV 4K (3rd generation) (at 1080p)"
  }
end

def device_os
  return {
    ios: "16.2",
    tvos: "16.1"
  }
end

def open_simulator_and_sleep(platform)
  return if platform == :macos # Don't need a sleep on macOS because it runs first.
  #Not working on xcode > 14
  #sh "xcrun instruments -w '#{device_names[platform]} (#{device_os[platform]})' || sleep 15"
end

def xcodebuild(tasks, platform, xcprety_args: '', xcode_summary: false)
  sdk = sdks[platform]
  scheme = schemes[platform]
  destination = devices[platform]

  open_simulator_and_sleep(platform)
  xcpretty_json_output_name = xcode_summary == true ? " XCPRETTY_JSON_FILE_OUTPUT=\"xcodebuild-#{platform}.json\"" : ""
  xcpretty_formatter = xcode_summary == true ? " -f `bundle exec xcpretty-json-formatter`" : ""
  system "set -o pipefail && xcodebuild -project '#{moya_project}' -scheme '#{scheme}' -configuration '#{configuration}' -sdk #{sdk} -destination '#{destination}' #{tasks} |#{xcpretty_json_output_name} bundle exec xcpretty -c #{xcprety_args}#{xcpretty_formatter}"
end

def xcodebuild_example(tasks, xcprety_args: '')
  platform = :ios
  sdk = sdks[platform]
  destination = devices[platform]
  demo_project = 'Moya.xcodeproj'
  demo_scheme = 'Basic'

  open_simulator_and_sleep(platform)
  system "set -o pipefail && xcodebuild -project '#{demo_project}' -scheme '#{demo_scheme}' -configuration '#{configuration}' -sdk #{sdk} -destination '#{destination}' #{tasks} | bundle exec xcpretty -c #{xcprety_args}"
end

desc 'Build Moya.'
task :build do
  xcodebuild 'build', :ios
end

desc 'Build the Demo app.'
task :build_example do
  xcodebuild_example 'build'
end

desc 'Clean build directory.'
task :clean do
  xcodebuild 'clean', :ios
end

desc 'Build, then run all tests.'
task :test do
  targets.map do |platform|
    puts "Testing on #{platform}."
    xcodebuild 'build test', platform, xcprety_args: '--test', xcode_summary: true
  end
end

desc 'Individual test tasks.'
namespace :test do
  desc 'Test on iOS.'
  task :ios do
    xcodebuild 'build test', :ios, xcprety_args: '--test', xcode_summary: true
  end

  desc 'Test on macOS.'
  task :macos do
    xcodebuild 'build test', :macos, xcprety_args: '--test', xcode_summary: true
  end

  desc 'Test on tvOS.'
  task :tvos do
    xcodebuild 'build test', :tvos, xcprety_args: '--test', xcode_summary: true
  end
end

desc 'Release a version, specified as an argument.'
task :create_release, :version do |task, args|
  puts "Pushing as a GitHub Release."
  require 'octokit'
  version = args[:version]
  changelog_filename = "CHANGELOG.md"
  changelog = File.read(changelog_filename)
  Octokit::Client.new(netrc: true).
    create_release('Moya/Moya',
                   version,
                   name: version,
                   body: changelog.split(/^# /)[2].strip)
end
