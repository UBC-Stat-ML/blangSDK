#!/bin/bash

## First, setup the ace hack

# copy blang file
cp blang.js ace-master/lib/ace/mode/
cp xtend.js ace-master/lib/ace/mode/

cd ace-master
npm clean
npm install
node Makefile.dryice.js
cd ..

rm -rf www/ace
cp -r ace-master/build/src/ www/ace


## Then, generate the actual documentation

# Rebuild source
cd ..
./setup-cli.sh
cd -

# Run the document generator
cd www
java -cp ../../build/install/blang/lib/\* blang.runtime.internals.doc.MakeHTMLDoc
cd -


##### Javadocs

## DSL

cd ../../blangDSL/ca.ubc.stat.blang.parent
./gradlew assemble
cd -

rm -rf www/javadoc-dsl
mv ../../blangDSL/ca.ubc.stat.blang.parent/ca.ubc.stat.blang/build/docs/javadoc www/javadoc-dsl



## xlinear

cd ../../xlinear
./gradlew assemble
cd -

rm -rf www/javadoc-xlinear
mv ../../xlinear/build/docs/javadoc www/javadoc-xlinear


## inits

cd ../../inits
./gradlew assemble
cd -

rm -rf www/javadoc-inits
mv ../../inits/build/docs/javadoc www/javadoc-inits


## SDK

cd ..
./gradlew assemble
cd -

rm -rf www/javadoc-sdk
mv ../build/docs/javadoc www/javadoc-sdk

