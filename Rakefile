# xcodebuild often ends with error code 65 and needs to be restarted.
# This function will re-run a command up to three times if it yeilds a 65 exit code.
def safe_sh(command)
  attempt_count = 0
  while true
    begin
      attempt_count += 1
      sh command # Attempt command
      break      # If command was successful, break out of the loop.
    rescue => exception
      puts "Received non-zero exit code: #{$1}"
      raise exception unless attempt_count < 2 # Ignore exit code 65
    end
  end
end

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
    ios: 'MoyaTests',
    macos: 'MoyaTests',
    tvos: 'MoyaTests'
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
    macos: "arch=x86_64",
    tvos: "OS=#{device_os[:tvos]},name=#{device_names[:tvos]}"
  }
end

def device_names
  return {
    ios: "iPhone 8",
    tvos: "Apple TV 4K (at 1080p) (2nd generation)"
  }
end

def device_os
  return {
    ios: "14.5",
    tvos: "14.5"
  }
end

def open_simulator_and_sleep(platform)
  return if platform == :macos # Don't need a sleep on macOS because it runs first.
  sh "xcrun instruments -w '#{device_names[platform]} (#{device_os[platform]})' || sleep 15"
end

def xcodebuild(tasks, platform, xcprety_args: '', xcode_summary: false)
  sdk = sdks[platform]
  scheme = schemes[platform]
  destination = devices[platform]

  open_simulator_and_sleep(platform)
  xcpretty_json_output_name = xcode_summary == true ? " XCPRETTY_JSON_FILE_OUTPUT=\"xcodebuild-#{platform}.json\"" : ""
  xcpretty_formatter = xcode_summary == true ? " -f `bundle exec xcpretty-json-formatter`" : ""
  safe_sh "set -o pipefail && xcodebuild -project '#{moya_project}' -scheme '#{scheme}' -configuration '#{configuration}' -sdk #{sdk} -destination '#{destination}' #{tasks} |#{xcpretty_json_output_name} bundle exec xcpretty -c #{xcprety_args}#{xcpretty_formatter}"
end

def xcodebuild_example(tasks, xcprety_args: '')
  platform = :ios
  sdk = sdks[platform]
  destination = devices[platform]
  demo_project = 'Moya.xcodeproj'
  demo_scheme = 'Basic'

  open_simulator_and_sleep(platform)
  safe_sh "set -o pipefail && xcodebuild -project '#{demo_project}' -scheme '#{demo_scheme}' -configuration '#{configuration}' -sdk #{sdk} -destination '#{destination}' #{tasks} | bundle exec xcpretty -c #{xcprety_args}"
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

  desc 'Run a local copy of Carthage on this current directory.'
  task :carthage do
    # make a folder, put a cartfile in and make it a consumer
    # of the root dir

    Dir.mkdir("carthage_test")
    File.write(File.join("carthage_test", "Cartfile"), "git \"file://#{Dir.pwd}\" \"HEAD\"")
    Dir.chdir "carthage_test" do
      sh "../scripts/carthage.sh bootstrap --platform 'iOS'"
      has_artifacts = Dir.glob("Carthage/Build/*").count > 0
      raise("Carthage did not succeed") unless has_artifacts
    end
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
