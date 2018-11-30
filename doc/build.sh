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