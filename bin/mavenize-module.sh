#!/usr/bin/env bash

#
# This script is designed to copy the appropriate files from an extracted RText source zip or a subversion 
# checkout into a src folder that can then be built with maven
#

function usage(){
    echo -e "\nYou must specify a source folder and version e.g. './`basename $0` -f=<sourceFolder> -v=<sourceVersion>'"
    echo -e "\n*** Available Parameters ***\n"
    echo -e "-f | --folder \t\t\t set the source folder"
    echo -e "-v | --version \t\t\t set the source version\n"
    echo -e "-c | --commitId \t\t\t set the git commit ID\n"
    echo -e "-h | --help \t\t\t Show this help!"
    exit 1
}

for _argument in "$@"
do
    case ${_argument} in
        -f=*|--folder=*)
        _sourceFolder="${_argument#*=}"
        ;;
        -v=*|--version=*)
        _sourceVersion="${_argument#*=}"
        ;;
        -c|--commitId)
        _gitCommitId=="${_argument#*=}"
        ;;
        -h|--help)
        usage
        ;;
    esac
done

if [ "" == "$_sourceVersion" ]; then
	usage
	exit 1
fi

if [ "" == "$_sourceVersion" ] || [ ! -f "$_sourceFolder" ]; then
 	usage
	exit 1
fi

echo "Mavenizing using source jar/folder ( $_sourceFolder ) with source version ( $_sourceVersion )"

targetFolder=src
mainJavaFolder=$targetFolder/main/java
mainResourcesFolder=$targetFolder/main/resources
testJavaFolder=$targetFolder/test/java
testResourcesFolder=$targetFolder/test/resources

function replaceVersionPlaceHolder {
	placeHolderPattern=$1
    placeHolderVersion=$2
	foundPlaceHolderVersion=`grep $placeHolderPattern pom.xml  | wc -l`
	#echo "foundPlaceHolderVersion: $foundPlaceHolderVersion"
	if [ "$foundPlaceHolderVersion" -gt "0" ]; then
		#read -p "What value for the $placeHolderPattern dependency version should be used? " placeHolderVersion
		sed -i "" "s/@${placeHolderPattern}@/${placeHolderVersion}/" pom.xml
	fi
}

# We have a source artifact instead of a source folder.  So we need to extract it into a tmp
# directory and assign the sourceFolder variable to that tmp directory.
artifactFilename=`basename ${_sourceFolder}`
curDirPath=`pwd`;
curDirName=`basename $curDirPath`

rm -rf ${artifactFilename}.tmp
mkdir ${artifactFilename}.tmp
cp ${_sourceFolder} ${artifactFilename}.tmp/${artifactFilename}
pushd ${artifactFilename}.tmp > /dev/null
unzip -q ${artifactFilename}
if [ "$?" -ne "0" ]; then
    echo "Unzip failed to extract archive: $_sourceFolder"
    exit 1
fi

# Since rtext source zip ships both RText source and Common source trees, detect this and remove
# the irrelevant source tree.
isRtextArtifact=`echo "$artifactFilename" | egrep "^rtext_.*_Source\.zip" | wc -l`
if [ "$isRtextArtifact" -eq 1 ]; then

    if [ "$curDirName" == "rtext" ]; then
        echo "Removing common artifact source files (keeping RText source files)"
        rm -rf Common
        mv RText/* .
        rmdir RText
    else
        echo "Removing rtext artifact source files (keeping Common source files)"
        rm -rf RText
        mv Common/* .
        rmdir Common
    fi
fi
popd > /dev/null
_sourceFolder=${artifactFilename}.tmp
sed -i "" "s/@VERSION@/${_sourceVersion}/" pom.xml

replaceVersionPlaceHolder "RSYNTAXTEXTAREAVERSION" $RSYNTAXTEXTAREA_VERSION
replaceVersionPlaceHolder "SPELLCHECKERVERSION" $SPELLCHECKER_VERSION
replaceVersionPlaceHolder "RSTAUIVERSION" $RSTA_UI_VERSION
replaceVersionPlaceHolder "RTEXTCOMMONVERSION" $RTEXTCOMMON_VERSION
replaceVersionPlaceHolder "AUTOCOMPLETEVERSION" $AUTOCOMPLETE_VERSION
replaceVersionPlaceHolder "LANGUAGESUPPORTVERSION" $LANGUAGESUPPORT_VERSION
replaceVersionPlaceHolder "GITCOMMITID" $GITCOMMITID

rm -rf "$targetFolder"
mkdir "$targetFolder"

mkdir -p "$mainJavaFolder"
mkdir -p "$mainResourcesFolder"

# Copy main classes and resources
cp -r "$_sourceFolder/src/org" "$mainJavaFolder"
cp -r "$_sourceFolder/src/org" "$mainResourcesFolder"
find "$mainJavaFolder" -type f -not -name "*.java" -delete
find "$mainResourcesFolder" -type f -name "*.java" -delete
find "$mainResourcesFolder" -type f -name "*.flex" -delete

# For rtext-common, there is an interface in the com package that is 
# required to compile the source
if [ -f "$_sourceFolder/extra/com/apple/osxadapter/NativeMacApp.java" ]; then
	mkdir -p "$mainJavaFolder/com/apple/osxadapter/"
	cp "$_sourceFolder/extra/com/apple/osxadapter/NativeMacApp.java" "$mainJavaFolder/com/apple/osxadapter/NativeMacApp.java"

        # Although common ships this source file, we cannot compile it because it relies on Apple java library classes.  While
        # these are available in Maven Central, they are compiled with a different JDK version:
	# [ERROR] bad class file: /home/manningr/.m2/repository/com/apple/AppleJavaExtensions/1.4/AppleJavaExtensions-1.4.jar(com/apple/eawt/ApplicationAdapter.class)
	# [ERROR] class file has wrong version 49.0, should be 48.0
	#
	#cp "$sourceFolder/extra/com/apple/osxadapter/OSXAdapter.java" "$mainJavaFolder/com/apple/osxadapter/OSXAdapter.java"
fi

# Copy translation property files
if [ -d "$_sourceFolder/i18n" ]; then
	cp -r "$_sourceFolder/i18n/org" "$mainResourcesFolder"
fi

# Copy image files
if [ -d "$_sourceFolder/img" ]; then
	cp -r "$_sourceFolder/img/org" "$mainResourcesFolder"
fi

# Copy a theme.dtd file if it exists
if [ -f "$_sourceFolder/src/theme.dtd" ]; then
	cp "$_sourceFolder/src/theme.dtd" "$mainResourcesFolder"
fi

# Now copy any test classes and resources if a test folder exists
if [ -d "$_sourceFolder/test" ]; then
	mkdir -p "$testJavaFolder"
	mkdir -p "$testResourcesFolder"
	cp -r "$_sourceFolder/test/org" "$testJavaFolder"
	cp -r "$_sourceFolder/test/org" "$testResourcesFolder"
	find "$testJavaFolder" -type f | grep -v "\.java" -delete
	find "$testResourcesFolder" -type f -name "*.java" -delete
fi

# Now copy in any test resources if a res/test folder exists (in particular, this is need for languagesupport module
if [ -d "$_sourceFolder/res" ]; then
	mkdir -p "$testResourcesFolder"
	cp -r "$_sourceFolder/res" "$testResourcesFolder"
fi

# This is a hack to fix a test in the languagesupport module
if [ -f "./src/test/java/org/fife/rsta/ac/java/rjc/parser/ClassAndLocalVariablesTest.java" ]; then
	sed -i "" "s!res/tests/SimpleClass.java!src/test/resources/res/tests/SimpleClass.java!" "./src/test/java/org/fife/rsta/ac/java/rjc/parser/ClassAndLocalVariablesTest.java"
fi

# language support requires some xml files from the "data" directory.
if [ -d "$_sourceFolder/data" ]; then
	mkdir "$mainResourcesFolder/data"
	cp  $_sourceFolder/data/*.xml "$mainResourcesFolder/data"
fi

exit 0