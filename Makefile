WORKSPACE = Demo.xcworkspace
SCHEME = Demo
CONFIGURATION = Debug
DEVICE_HOST = platform='iOS Simulator',OS='9.0',name='iPhone 6'

# Default for `make`
all: ci

build:
	cd Demo ; set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' -sdk iphonesimulator -destination $(DEVICE_HOST) build | xcpretty -c

clean:
	cd Demo ; xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' clean

test:
	cd Demo ; set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' build test -sdk iphonesimulator -destination $(DEVICE_HOST) | xcpretty -c --test

setup:
	cd Demo ; bundle install ; bundle exec pod install

ci: test
