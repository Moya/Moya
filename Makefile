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
	# Ensure that Moya, RxMoya, and ReactiveMoya are built
	carthage build --no-skip-current;
	# Execute the test suite
	cd $(EXAMPLE_DIR) ; set -o pipefail && xcodebuild -project '$(PROJECT)' -scheme '$(SCHEME)' -configuration '$(CONFIGURATION)' test -sdk iphonesimulator -destination 'name=iPhone 5' | xcpretty -c --test

setup:
	# Install carthage, and update dependencies
	brew install carthage; carthage update;

ci: test
