#!/bin/bash

./gradlew clean
./gradlew installDist

# Fix problem arising if eclipse is used jointly
mkdir build/xtend/test
mkdir build/blang/test

if hash blang 2>/dev/null; then
    echo "CLI setup complete."
else
    echo "Add the following to classpath: $(pwd)/build/install/blang/bin/"
fi


./gradlew eclipse

# Fix some stuff that get broken everytime
git -c diff.mnemonicprefix=false -c core.quotepath=false -c credential.helper=sourcetree checkout -- .settings/ca.ubc.stat.blang.BlangDsl.prefs .settings/org.eclipse.jdt.core.prefs .settings/org.eclipse.xtend.core.Xtend.prefs .settings/org.eclipse.xtext.java.Java.prefs
mkdir build
mkdir build/blang
mkdir build/blang/test
mkdir build/blang/main
mkdir -p build/xtend/main
mkdir -p build/xtend/test

echo "Eclipse setup complete."