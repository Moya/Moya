# This code is replacing `-weak_framework Combine` with `` for Xcode 10 builds and the other way around for Xcode 11+.
if [ $XCODE_VERSION_MAJOR -ge 1100 ]; then
    sed -ie 's,OTHER_LDFLAGS = $OTHER_LDFLAGS_XCODE10,OTHER_LDFLAGS = $OTHER_LDFLAGS_XCODE11,g' "$SRCROOT/Moya.xcodeproj/project.pbxproj"
else
    sed -ie 's,OTHER_LDFLAGS = $OTHER_LDFLAGS_XCODE11,OTHER_LDFLAGS = $OTHER_LDFLAGS_XCODE10,g' "$SRCROOT/Moya.xcodeproj/project.pbxproj"
fi;