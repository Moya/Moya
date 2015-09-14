def xcodebuild_in_demo_dir(tasks, xcprety_args: '')
  workspace = 'Demo.xcworkspace'
  scheme = 'Demo'
  configuration = 'Debug'
  device_host = "platform='iOS Simulator',OS='9.0',name='iPhone 6'"

  Dir.chdir('Demo') do
    sh "set -o pipefail && xcodebuild -workspace '#{workspace}' -scheme '#{scheme}' -configuration '#{configuration}' -sdk iphonesimulator -destination #{device_host} #{tasks} | xcpretty -c #{xcprety_args}"
  end
end

desc 'Build the Demo app.'
task :build do
  xcodebuild_in_demo_dir 'build'
end

desc 'Clean build directory.'
task :clean do
  xcodebuild_in_demo_dir 'clean'
end

desc 'Build, then run tests.'
task :test do
  xcodebuild_in_demo_dir 'build test', xcprety_args: '--test'
end

desc 'Release a version, specified as an argument.'
task :release, :version do |task, args|
  version = args[:title]
  abort "You must specify a version in semver format." if version.nil? || version.scan(/\d+\.\d+\.\d+/).length == 0

  Dir.chdir('Demo') do
    sh "pod update Moya"
  end

  message = "Releasing version #{version}."
  sh "git commit -am #{message}"
  sh "git tag #{version} -m #{message}"
  sh "git push --follow-tags"
  sh "pod trunk push Moya.podspec"

  ['Moya', 'RxMoya', 'ReactiveMoya'].each do |podspec|
    filename = "#{podspec}.podspec"
    contents = File.read(filename)
    contents!.gsub(/s\.version\s*=\s"\d+\.\d+\.\d+"/, "s.version      = \"#{version}\"")
    File.open(filename, 'w') { |file| file.puts contents }
  end

  changelog_filename = "CHANGELOG.md"
  changelog = File.read(changelog_filename)
  changelog.gsub!(/# Next/, "# Next\n\n# #{version}")
  File.open(changelog_filename, 'w') { |file| file.puts changelog }
end
