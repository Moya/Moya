EXAMPLE_DIR = Example
WORKSPACE = MoyaExample.xcworkspace
SCHEME = MoyaExample
CONFIGURATION = Debug

# Default for `make`
all: ci

build:
	cd $(EXAMPLE_DIR) ; set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' -sdk iphonesimulator -destination 'name=iPhone 5' build | xcpretty -c

clean:
	cd $(EXAMPLE_DIR) ; xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' clean

test:
	cd $(EXAMPLE_DIR) ; set -o pipefail && xcodebuild -workspace '$(WORKSPACE)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' test -sdk iphonesimulator -destination 'name=iPhone 5' | xcpretty -c --test
	carthage build --no-skip-current

setup:
	cd $(EXAMPLE_DIR) ; bundle install ; bundle exec pod install ; brew install carthage

ci: test
