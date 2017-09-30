#!/bin/sh

carthage bootstrap --cache-builds
cp Cartfile.resolved Carthage
