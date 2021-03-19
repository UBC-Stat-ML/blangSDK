#!/bin/bash


# nb: eclipse executable in Eclipse.app/Contents/MacOS
# list features: ./eclipse -clean -purgeHistory -application org.eclipse.equinox.p2.director -noSplash -repository https://www.stat.ubc.ca/~bouchard/maven/blang-eclipse-plugin-latest/  -list

CUR=`pwd`

cd ../..
./setup-cli.sh
cd -


blang_folder=blang
rm -rf $blang_folder
mkdir $blang_folder

### Setup eclipse

cp -r plain-eclipse/Eclipse.app $blang_folder/BlangIDE.app

$blang_folder/BlangIDE.app/Contents/MacOS/eclipse \
  -clean -purgeHistory \
  -application org.eclipse.equinox.p2.director \
  -noSplash \
  -repository https://www.stat.ubc.ca/~bouchard/maven/blang-eclipse-plugin-latest/ \
  -installIUs ca.ubc.stat.blang.feature.feature.group

sudo codesign --force --sign - $blang_folder/BlangIDE.app


### Setup blang-related projects in workspace

cd $blang_folder
mkdir workspace
cd workspace

create-blang-gradle-project --name blangExample --githubOrganization UBC-Stat-ML

git clone https://github.com/UBC-Stat-ML/blangSDK.git


### Package things up into a zip

cd $CUR

zip -r $blang_folder $blang_folder
mkdir ../www/downloads
mv ${blang_folder}.zip ../www/downloads/blang-mac-latest.zip

rm -rf $blang_folder
