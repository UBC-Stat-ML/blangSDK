#!/bin/bash

./gradlew eclipse

# Fix some stuff that get broken everytime
git -c diff.mnemonicprefix=false -c core.quotepath=false -c credential.helper=sourcetree checkout -- .settings/ca.ubc.stat.blang.BlangDsl.prefs .settings/org.eclipse.jdt.core.prefs .settings/org.eclipse.xtend.core.Xtend.prefs .settings/org.eclipse.xtext.java.Java.prefs
mkdir build
mkdir build/blang
mkdir build/blang/test
mkdir build/blang/main
mkdir build/xtend/main
mkdir build/xtend/test

echo Done
