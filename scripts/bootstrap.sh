#!/bin/sh

carthage bootstrap --use-xcframeworks
cp Cartfile.resolved Carthage
