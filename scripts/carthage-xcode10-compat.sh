#!/bin/bash

# This code is replacing `-weak_framework Combine` with `` for Xcode < 11 builds.
# Can be removed once we stop supporting Xcode 9/10.
# When removing this script, also:
#     - remove two user-defined build settings: OTHER_LDFLAGS_XCODE10, OTHER_LDFLAGS_XCODE11
#     - also remove value for OTHER_LDFLAGS build settings (which is probably gonna equal $OTHER_LDFLAGS_XCODE11)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
sed -ie 's,OTHER_LDFLAGS = $OTHER_LDFLAGS_XCODE11,OTHER_LDFLAGS = $OTHER_LDFLAGS_XCODE10,g' "$DIR/../Moya.xcodeproj/project.pbxproj"