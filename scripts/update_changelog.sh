#!/bin/bash

NOW=$(date +'%Y-%m-%d')
sed "s/# Next/\\$(printf '# Next\\\n\\\n# '"[$VERSION] - $NOW")/" Changelog.md > tmpCHANGELOG.md
mv -f tmpCHANGELOG.md Changelog.md
