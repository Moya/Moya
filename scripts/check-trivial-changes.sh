#!/bin/sh

CHANGED_FILES=$(git show --name-only --pretty="" $CIRCLE_SHA1)

if grep -qvE '(\.(md|yml)$)|(^(docs|web))/' <<< $CHANGED_FILES ; then
  exit 1
fi

echo "Only docs were updated, stopping build!"
exit 0
