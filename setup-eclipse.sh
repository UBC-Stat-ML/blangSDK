#!/bin/bash

./gradlew eclipse

# Fix some stuff that get broken everytime
git -c diff.mnemonicprefix=false -c core.quotepath=false -c credential.helper=sourcetree checkout -- .settings/ca.ubc.stat.blang.BlangDsl.prefs .settings/org.eclipse.jdt.core.prefs .settings/org.eclipse.xtend.core.Xtend.prefs .settings/org.eclipse.xtext.java.Java.prefs
mkdir -p build
mkdir -p build/blang
mkdir -p build/blang/test
mkdir -p build/blang/main
mkdir -p build/xtend/main
mkdir -p build/xtend/test

echo Done
