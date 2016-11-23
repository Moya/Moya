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

def workspace
  return 'Demo.xcworkspace'
end

def configuration
  return 'Debug'
end

def targets
  return [
    # :macos, # Note: we're experiencing macOS build problems on circle, commenting out.
    :tvos,
    :ios
  ]
end

def schemes
  return {
    ios: 'Demo',
    macos: 'MoyaTests-Mac',
    tvos: 'MoyaTests-tvOS'
  }
end

def sdks
  return {
    ios: 'iphonesimulator',
    macos: 'macosx',
    tvos: 'appletvsimulator'
  }
end

# See: https://discuss.circleci.com/t/multiple-ios-simulators-available-for-single-os-device-configurations/7854
def devices
  return {
    ios: ENV['CIRCLECI'] ? "id='F08BA729-6AD2-42DF-A210-34DC8D990011'" : "name='iPhone 6s'",
    macos: "arch='x86_64'",
    tvos: ENV['CIRCLECI'] ? "id='48B0E1AB-F5EB-40FB-9372-A16B93349B12'" : "name='Apple TV 1080p'"
  }
end

# See: https://discuss.circleci.com/t/xcode-exit-code-65/4284/13
def uuids
  return {
    ios: 'F08BA729-6AD2-42DF-A210-34DC8D990011', # iPhone 6s
    tvos: '48B0E1AB-F5EB-40FB-9372-A16B93349B12' # Apple TV 1080p
  }
end

def open_simulator_and_sleep(uuid)
  return if uuid.nil? # Don't need a sleep on macOS because it runs first.
  sh "xcrun instruments -w '#{uuid}' || sleep 15"
end

def xcodebuild_in_demo_dir(tasks, platform, xcprety_args: '')
  sdk = sdks[platform]
  scheme = schemes[platform]
  destination = devices[platform]

  Dir.chdir('Demo') do
    open_simulator_and_sleep(uuids[platform])
    safe_sh "set -o pipefail && xcodebuild -workspace '#{workspace}' -scheme '#{scheme}' -configuration '#{configuration}' -sdk #{sdk} -destination #{destination} #{tasks} | bundle exec xcpretty -c #{xcprety_args}"
  end
end

desc 'Build the Demo app.'
task :build do
  xcodebuild_in_demo_dir 'build', :ios
end

desc 'Clean build directory.'
task :clean do
  xcodebuild_in_demo_dir 'clean', :ios
end

desc 'Build, then run all tests.'
task :test do
  targets.map do |platform|
    puts "Testing on #{platform}."
    xcodebuild_in_demo_dir 'build test', platform, xcprety_args: '--test'
    sh "killall Simulator"
  end
end

desc 'Individual test tasks.'
namespace :test do
  desc 'Test on iOS.'
  task :ios do
    xcodebuild_in_demo_dir 'build test', :ios, xcprety_args: '--test'
    sh "killall Simulator"
  end

  desc 'Test on macOS.'
  task :macos do
    xcodebuild_in_demo_dir 'build test', :macos, xcprety_args: '--test'
  end

  desc 'Test on tvOS.'
  task :tvos do
    xcodebuild_in_demo_dir 'build test', :tvos, xcprety_args: '--test'
    sh "killall Simulator"
  end

  desc 'Run a local copy of Carthage on this current directory.'
  task :carthage do
    # make a folder, put a cartfile in and make it a consumer
    # of the root dir

    Dir.mkdir("carthage_test")
    File.write(File.join("carthage_test", "Cartfile"), "git \"file://#{Dir.pwd}\"")
    Dir.chdir "carthage_test" do
      sh "carthage bootstrap --platform 'iOS'"
      has_artifacts = Dir.glob("Carthage/Build/*").count > 0
      raise("Carthage did not succeed") unless has_artifacts
    end
  end
end

desc 'Release a version, specified as an argument.'
task :release, :version do |task, args|
  version = args[:version]
  # Needs a X.Y.Z-text format.
  abort "You must specify a version in semver format." if version.nil? || version.scan(/\d+\.\d+\.\d+/).length == 0

  puts "Updating podspec."
  filename = "Moya.podspec"
  contents = File.read(filename)
  contents.gsub!(/s\.version\s*=\s"\d+\.\d+\.\d+"/, "s.version      = \"#{version}\"")
  File.open(filename, 'w') { |file| file.puts contents }

  puts "Updating Demo project."
  Dir.chdir('Demo') do
    ENV['COCOAPODS_DISABLE_DETERMINISTIC_UUIDS'] = 'true'
    sh "bundle exec pod update Moya"
  end

  puts "Updating changelog."
  changelog_filename = "CHANGELOG.md"
  changelog = File.read(changelog_filename)
  changelog.gsub!(/# Next/, "# Next\n\n# #{version}")
  File.open(changelog_filename, 'w') { |file| file.puts changelog }

  puts "Comitting, tagging, and pushing."
  message = "Releasing version #{version}."
  sh "git commit -am '#{message}'"
  sh "git tag #{version} -m '#{message}'"
  sh "git push --follow-tags"

  puts "Pushing to CocoaPods trunk."
  sh "bundle exec pod trunk push Moya.podspec --allow-warnings"

  puts "Pushing as a GitHub Release."
  require 'octokit'
  Octokit::Client.new(netrc: true).
    create_release('Moya/Moya',
                   version,
                   name: version,
                   body: changelog.split(/^# /)[2].strip)
end
