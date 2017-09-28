#!/bin/sh

CHANGED_FILES=$(git show --name-only --pretty="" $CIRCLE_SHA1)

# Temporary printing for testing purposes
echo $CIRCLE_SHA1
echo $CHANGED_FILES

if grep -qvE '(\.md$)|(^(docs|web))/' <<< $CHANGED_FILES ; then
  exit 0
fi

echo "Only docs were updated, stopping build!"
exit 1
