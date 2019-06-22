#!/bin/bash

# Setup CLI
./gradlew clean
./gradlew installDist

# Fix problem arising if eclipse is used jointly
mkdir -p build/xtend/test
mkdir -p build/blang/test


# Setup Eclipse
./gradlew eclipse

# Fix some stuff that get broken everytime
git -c diff.mnemonicprefix=false -c core.quotepath=false -c credential.helper=sourcetree checkout -- .settings/ca.ubc.stat.blang.BlangDsl.prefs .settings/org.eclipse.jdt.core.prefs .settings/org.eclipse.xtend.core.Xtend.prefs .settings/org.eclipse.xtext.java.Java.prefs
mkdir build/blang/main
mkdir build/xtend/main



# Completion messages.

echo "Eclipse setup complete."

if hash blang 2>/dev/null; then
    echo "CLI setup complete."
else
    echo "Add the following to classpath: $(pwd)/build/install/blang/bin/"
fi