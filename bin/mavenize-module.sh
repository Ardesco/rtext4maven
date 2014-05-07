#! /bin/bash 

#
# This script is designed to copy the appropriate files from an extracted RText source zip or a subversion 
# checkout into a src folder that can then be built with maven
#

# This is the folder that contains the files that are currently built with Ant.
sourceFolder=$1
sourceVersion=$2
gitCommitId=$3
echo "Mavenizing using source jar/folder ( $sourceFolder ) with source version ( $sourceVersion )"


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
		echo "Using $placeHolderVersion as the value for the $placeHolderPattern"
		perl -pi -e "s/\@$placeHolderPattern\@/$placeHolderVersion/" pom.xml
	fi
}


if [ "" == "$sourceVersion" ]; then 
	echo "Usage: mavenize.sh <source folder> <source version>"
        echo "No source version was specified"
	exit 1
fi


if [ ! -d "$sourceFolder" ]; then
	if [ ! -f "$sourceFolder" ]; then
		echo "Usage: mavenize.sh <source folder/artifact> <source version>"
        	echo "No source folder/file was specified: $sourceFolder"
		exit 1
        else
		# We have a source artifact instead of a source folder.  So we need to extract it into a tmp
		# directory and assign the sourceFolder variable to that tmp directory.
		artifactFilename=`basename ${sourceFolder}`
		curDirPath=`pwd`;
		curDirName=`basename $curDirPath`
			
		rm -rf ${artifactFilename}.tmp
		mkdir ${artifactFilename}.tmp
		cp ${sourceFolder} ${artifactFilename}.tmp/${artifactFilename}
		pushd ${artifactFilename}.tmp
		unzip -q ${artifactFilename}
        if [ "$?" -ne "0" ]; then 
            echo "Unzip failed to extract archive: $sourceFolder"
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
		popd
		sourceFolder=${artifactFilename}.tmp
	fi
fi

perl -pi -e "s/\@VERSION\@/$sourceVersion/" pom.xml


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
cp -r "$sourceFolder/src/org" "$mainJavaFolder"
cp -r "$sourceFolder/src/org" "$mainResourcesFolder"
find "$mainJavaFolder" -type f | grep -v "\.java" | xargs -i rm {}
find "$mainResourcesFolder" -type f -name "*.java" | xargs -i rm {}
find "$mainResourcesFolder" -type f -name "*.flex" | xargs -i rm {}

# For rtext-common, there is an interface in the com package that is 
# required to compile the source
if [ -f "$sourceFolder/extra/com/apple/osxadapter/NativeMacApp.java" ]; then
	mkdir -p "$mainJavaFolder/com/apple/osxadapter/"
	cp "$sourceFolder/extra/com/apple/osxadapter/NativeMacApp.java" "$mainJavaFolder/com/apple/osxadapter/NativeMacApp.java"

        # Although common ships this source file, we cannot compile it because it relies on Apple java library classes.  While
        # these are available in Maven Central, they are compiled with a different JDK version:
	# [ERROR] bad class file: /home/manningr/.m2/repository/com/apple/AppleJavaExtensions/1.4/AppleJavaExtensions-1.4.jar(com/apple/eawt/ApplicationAdapter.class)
	# [ERROR] class file has wrong version 49.0, should be 48.0
	#
	#cp "$sourceFolder/extra/com/apple/osxadapter/OSXAdapter.java" "$mainJavaFolder/com/apple/osxadapter/OSXAdapter.java"
fi

# Copy translation property files
if [ -d "$sourceFolder/i18n" ]; then
	cp -r "$sourceFolder/i18n/org" "$mainResourcesFolder"
fi

# Copy image files
if [ -d "$sourceFolder/img" ]; then
	cp -r "$sourceFolder/img/org" "$mainResourcesFolder"
fi

# Copy a theme.dtd file if it exists
if [ -f "$sourceFolder/src/theme.dtd" ]; then
	cp "$sourceFolder/src/theme.dtd" "$mainResourcesFolder"
fi

# Now copy any test classes and resources if a test folder exists
if [ -d "$sourceFolder/test" ]; then
	mkdir -p "$testJavaFolder"
	mkdir -p "$testResourcesFolder"
	cp -r "$sourceFolder/test/org" "$testJavaFolder"
	cp -r "$sourceFolder/test/org" "$testResourcesFolder"
	find "$testJavaFolder" -type f | grep -v "\.java" | xargs -i rm {}
	find "$testResourcesFolder" -type f -name "*.java" | xargs -i rm {}
fi

# Now copy in any test resources if a res/test folder exists (in particular, this is need for languagesupport module
if [ -d "$sourceFolder/res" ]; then
	mkdir -p "$testResourcesFolder"
	cp -r "$sourceFolder/res" "$testResourcesFolder"
fi

# This is a hack to fix a test in the languagesupport module
if [ -f "./src/test/java/org/fife/rsta/ac/java/rjc/parser/ClassAndLocalVariablesTest.java" ]; then
	perl -pi -e 's/res\/tests\/SimpleClass\.java/src\/test\/resources\/res\/tests\/SimpleClass.java/' "./src/test/java/org/fife/rsta/ac/java/rjc/parser/ClassAndLocalVariablesTest.java";
fi

# language support requires some xml files from the "data" directory.
if [ -d "$sourceFolder/data" ]; then
	mkdir "$mainResourcesFolder/data"
	cp  $sourceFolder/data/*.xml "$mainResourcesFolder/data"
fi



exit 0

