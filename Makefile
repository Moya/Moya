EXAMPLE_DIR = Example
PROJECT = MoyaExample.xcodeproj
SCHEME = MoyaExample
CONFIGURATION = Debug

# Default for `make`
all: ci

build:
	cd $(EXAMPLE_DIR) ; set -o pipefail && xcodebuild -project '$(PROJECT)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' -sdk iphonesimulator -destination 'name=iPhone 5' build | xcpretty -c

clean:
	cd $(EXAMPLE_DIR) ; xcodebuild -project '$(PROJECT)' -scheme '$(SCHEME)' clean

test:
	carthage build --no-skip-current
	cd $(EXAMPLE_DIR) ; set -o pipefail && xcodebuild -project '$(PROJECT)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' test -sdk iphonesimulator -destination 'name=iPhone 5' | xcpretty -c --test

setup:
	cd $(EXAMPLE_DIR) ; bundle install ; bundle exec pod install ; brew install carthage; carthage update;

ci: test
