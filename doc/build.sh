#!/bin/bash


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
