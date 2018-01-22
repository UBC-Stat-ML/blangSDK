#!/bin/bash

./gradlew clean
./gradlew installDist

# Fix problem arising if eclipse is used jointly
mkdir build/xtend/test
mkdir build/blang/test

if hash blang 2>/dev/null; then
    echo "Done"
else
    echo "Add the following to classpath: $(pwd)/build/install/blang/bin/"
fi