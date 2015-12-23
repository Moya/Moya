def workspace
  return 'Demo.xcworkspace'
end

def configuration
  return 'Debug'
end

def targets
  return [
    :ios,
    :osx,
    :tvos
  ]
end

def schemes
  return {
    ios: 'Demo',
    osx: 'MoyaTests-Mac',
    tvos: 'MoyaTests-tvOS'
  }
end

def sdks
  return {
    ios: 'iphonesimulator',
    osx: 'macosx',
    tvos: 'appletvsimulator'
  }
end

def devices
  return {
    ios: "name='iPhone 6s'",
    osx: "arch='x86_64'",
    tvos: "name='Apple TV 1080p'"
  }
end

def xcodebuild_in_demo_dir(tasks, platform, xcprety_args: '')
  sdk = sdks[platform]
  scheme = schemes[platform]
  destination = devices[platform]

  Dir.chdir('Demo') do
    sh "set -o pipefail && xcodebuild -workspace '#{workspace}' -scheme '#{scheme}' -configuration '#{configuration}' -sdk #{sdk} -destination #{destination} #{tasks} | xcpretty -c #{xcprety_args}"
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

desc 'Build, then run tests.'
task :test do
  targets.map { |platform| xcodebuild_in_demo_dir 'build test', platform, xcprety_args: '--test' }
  sh "killall Simulator"
end

desc 'Release a version, specified as an argument.'
task :release, :version do |task, args|
  version = args[:version]
  abort "You must specify a version in semver format." if version.nil? || version.scan(/\d+\.\d+\.\d+/).length == 0

  puts "Updating podspec."
  filename = "Moya.podspec"
  contents = File.read(filename)
  contents.gsub!(/s\.version\s*=\s"\d+\.\d+\.\d+"/, "s.version      = \"#{version}\"")
  File.open(filename, 'w') { |file| file.puts contents }

  puts "Updating Demo project."
  Dir.chdir('Demo') do
    ENV['COCOAPODS_DISABLE_DETERMINISTIC_UUIDS'] = 'true'
    sh "pod update Moya"
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
  sh "pod trunk push Moya.podspec --allow-warnings"

  puts "Pushing as a GitHub Release."
  sh "git config release.tag-regex=\d+\.\d+\.\d+$"
  sh "git release"
end
