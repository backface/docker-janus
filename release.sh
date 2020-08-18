#!/bin/bash

docker run --rm -v "$PWD":/app treeder/bump patch
version=`cat VERSION`
echo "version: $version"

# tag it
git commit -m "v$version"
git tag -a "v$version" -m "$v$version"
git push
git push --tags
