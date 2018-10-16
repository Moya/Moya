#!/bin/sh

RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

if ! cmp -s Cartfile.resolved Carthage/Cartfile.resolved; then
  printf "${RED}Dependencies out of date with cache.${NC} Bootstrapping...\n"
  scripts/bootstrap.sh
else
  printf "${GREEN}Cache up-to-date.${NC} Skipping bootstrap...\n"
fi
