#!/bin/bash


# nb: eclipse executable in Eclipse.app/Contents/MacOS
# list features: ./eclipse -clean -purgeHistory -application org.eclipse.equinox.p2.director -noSplash -repository https://www.stat.ubc.ca/~bouchard/maven/blang-eclipse-plugin-latest/  -list

CUR=`pwd`

blang_folder=blang
rm -rf $blang_folder
mkdir $blang_folder

cp -r plain-eclipse/Eclipse.app $blang_folder/BlangIDE.app

$blang_folder/BlangIDE.app/Contents/MacOS/eclipse \
  -clean -purgeHistory \
  -application org.eclipse.equinox.p2.director \
  -noSplash \
  -repository https://www.stat.ubc.ca/~bouchard/maven/blang-eclipse-plugin-latest/ \
  -installIUs ca.ubc.stat.blang.feature.feature.group

sudo codesign --force --sign - $blang_folder/BlangIDE.app

cd $blang_folder
mkdir workspace
git clone git@github.com:UBC-Stat-ML/blangExample.git
cd blangExample
./gradlew eclipse

cd $CUR

zip -r $blang_folder $blang_folder
mkdir ../www/downloads
mv ${blang_folder}.zip ../www/downloads/blang-mac-latest.zip
