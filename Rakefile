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

task :clean do
  xcodebuild_in_demo_dir 'clean'
end

task :test do
  xcodebuild_in_demo_dir 'build test', xcprety_args: '--test'
end
