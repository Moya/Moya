WORKSPACE = Moya.xcworkspace
SCHEME = Moya
CONFIGURATION = Debug

# Default for `make`
all: ci

build:
	set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' -sdk iphonesimulator -destination 'name=iPhone 5' build | xcpretty -c

clean:
	xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' clean

test:
	set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration Debug test -sdk iphonesimulator -destination 'name=iPhone 5' | xcpretty -c --test

setup:
	bundle exec pod install

prepare_ci:	setup

ci: test
