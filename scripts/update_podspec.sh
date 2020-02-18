#!/bin/bash

SEMVER_REGEX="s\.version      = \"[0-9]*\.[0-9]*\.[0-9]*\(-.*\)\{0,1\}\""
sed "s/$SEMVER_REGEX/s.version      = \"$VERSION\"/" Moya.podspec > tmpPodspec
mv -f tmpPodspec Moya.podspec

