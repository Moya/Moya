#!/bin/sh

CHANGED_FILES=$(git show --name-only --pretty="" $CIRCLE_SHA1)

# Temporary regex added .sh to test that it ignores the fact I've changed this file
if grep -qvE '(\.(md|sh)$)|(^(docs|web))/' <<< $CHANGED_FILES ; then
  exit 0
fi

echo "Only docs were updated, stopping build!"
circleci step halt
