WORKSPACE = Demo.xcworkspace
SCHEME = Demo
CONFIGURATION = Debug

# Default for `make`
all: ci

build:
	cd Demo ; set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' -sdk iphonesimulator -destination 'name=iPhone 5' build | xcpretty -c

clean:
	cd Demo ; xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' clean

test:
	cd Demo ; set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' build test -sdk iphonesimulator -destination 'name=iPhone 5' | xcpretty -c --test
	carthage build --no-skip-current

setup:
	cd Demo ; bundle install ; bundle exec pod install ; brew install carthage

ci: test
