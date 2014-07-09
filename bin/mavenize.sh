#!/usr/bin/env bash

#
# This script will do the following:
#
# 1. Pull down the source for each RText/RSyntaxTextArea module according to the versions specified below.
# 2. Create the RText/RSyntaxTextArea module structure (i.e. root pom.xml rsyntaxtextarea-modules, rtext-modules. 
# 3. Copy the pre-built (but "template-ized") pom files into their correct locations with the module structure.
# 4. Extract the source from each downloaded artifact into their correct locations with the module structure.
# 5. Build all modules from the top down.
# 6. Compare the "maven-built" artifacts with the "official" compiled artifacts.
# 7. Create upload bundles for each of the artifacts containing source-jar, javadoc-jar, compiled-jar, and their respective GPG-signed files
# 
# Note: there are complications to this build process.  The original authors decided to remain "true" Java 1.4 compatible. 
# So this means that some of the code *will not* compile with a later JDK (even if you specify 1.4 as the source and target)
# In order to facilitate this in a portable build manner, you will need something like the following profile defined in settings.xml:
#
#
#		<profile>
#			<id>legacy-javac</id>
#			<properties>
#				<javac14-compiler-executable>/opt/j2sdk1.4.2_19/bin/javac</javac14-compiler-executable>
#				<javac16-compiler-executable>/opt/java6/bin/javac</javac16-compiler-executable>
#			</properties>			
#		</profile>
#
# Where most importantly, you will need to have a working 1.4 compiler executable specified as the value for javac14-compiler-executable 
#

#TODO testing purposes remove these when complete
export RSYNTAXTEXTAREA_VERSION=2.5.1
export AUTOCOMPLETE_VERSION=2.5.1
export SPELLCHECKER_VERSION=2.5.1
export RSTA_UI_VERSION=2.5.1
export RTEXT_VERSION=2.0.7
export RTEXTCOMMON_VERSION=2.0.7
export LANGUAGESUPPORT_VERSION=2.5.1


function usage(){
    echo -e "\nYou must specify a git revision e.g. './`basename $0` -r=8324c615b702e5dab0b3979a4fb3639a7c17bbdb'"
    echo -e "\n*** Available Parameters ***\n"
    echo -e "--rsyntaxarea \t\t\t set the rsyntaxarea version"
    echo -e "--autocomplete \t\t\t set the autocomplete version"
    echo -e "--spellchecker \t\t\t set the spellchecker version"
    echo -e "--rstaui \t\t\t set the rsta_ui version"
    echo -e "--rtext \t\t\t set the rtext version"
    echo -e "--rtextcommon \t\t\t set the rtextcommon version"
    echo -e "--languagesupport \t\t\t set the rsta language support version"
    echo -e "--gpgpassphrase \t\t\t set the gpgpassphrase used to sign the packages that are created\n"
    echo -e "-h | --help \t\t\t Show this help!"
    exit 1
}

for _argument in "$@"
do
    case ${_argument} in
        --rsyntaxarea=*)
        RSYNTAXTEXTAREA_VERSION="${_argument#*=}"
        ;;
        --autocomplete=*)
        AUTOCOMPLETE_VERSION="${_argument#*=}"
        ;;
        --spellchecker=*)
        SPELLCHECKER_VERSION="${_argument#*=}"
        ;;
        --rstaui=*)
        RSTA_UI_VERSION="${_argument#*=}"
        ;;
        --rtext=*)
        RTEXT_VERSION="${_argument#*=}"
        ;;
        --rtextcommon=*)
        RTEXTCOMMON_VERSION="${_argument#*=}"
        ;;
        --languagesupport=*)
        LANGUAGESUPPORT_VERSION="${_argument#*=}"
        ;;
        --gpgpassphrase=*)
        GPGPASSPHRASE="${_argument#*=}"
        ;;
        -h|--help)
        usage
        ;;
    esac
done

if [ "" == "$GPGPASSPHRASE" ]; then
	echo "Environment variable GPGPASSPHRASE must be defined"
	exit 1
fi

#TODO check that versions have been set via command line

#TODO FUTURE allow release of some components and not all?

CURRENT_DIRECTORY=`pwd`
SCRIPT_DIRECTORY=`dirname $0`
TOP_DIR=${CURRENT_DIRECTORY}${SCRIPT_DIRECTORY#?}
TOP_DIR=${TOP_DIR%/*}
BIN_DIR=${TOP_DIR}/bin
OFFICIAL_SOURCE_DIR=${TOP_DIR}/official-jars/source
OFFICIAL_COMPILED_DIR=${TOP_DIR}/official-jars/compiled

# This is the root directory of the mavenized RText artifacts.
export OUTPUT_DIR=${TOP_DIR}/output
export SF_PROJECT_URI_BASE=http://sourceforge.net/projects

#
# rsyntaxtextarea-related module variables.
#
RSYNTAXTEXTAREA_MODULES_DIR=$OUTPUT_DIR/rsyntaxtextarea-modules
RSYNTAX_BASE=http://sourceforge.net/projects/rsyntaxtextarea/files

RSYNTAXTEXTAREA_SOURCE_ARCHIVE=rsyntaxtextarea_${RSYNTAXTEXTAREA_VERSION}_Source.zip
RSYNTAXTEXTAREA_COMPILE_ARCHIVE=rsyntaxtextarea_${RSYNTAXTEXTAREA_VERSION}.zip
RSYNTAXTEXTAREA_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/rsyntaxtextarea

AUTOCOMPLETE_SOURCE_ARCHIVE=autocomplete_${AUTOCOMPLETE_VERSION}_Source.zip
AUTOCOMPLETE_COMPILE_ARCHIVE=autocomplete_${AUTOCOMPLETE_VERSION}.zip
AUTOCOMPLETE_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/autocomplete

SPELLCHECKER_SOURCE_ARCHIVE=rsta_spellchecker_${SPELLCHECKER_VERSION}_Source.zip
SPELLCHECKER_COMPILE_ARCHIVE=rsta_spellchecker_${SPELLCHECKER_VERSION}.zip	
SPELLCHECKER_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/spellchecker

RSTA_UI_SOURCE_ARCHIVE=rstaui_${RSTA_UI_VERSION}_Source.zip
RSTA_UI_COMPILE_ARCHIVE=rstaui_${RSTA_UI_VERSION}.zip
RSTA_UI_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/rstaui

LANGUAGESUPPORT_SOURCE_ARCHIVE=RSTALanguageSupport_${LANGUAGESUPPORT_VERSION}_source.zip
LANGUAGESUPPORT_COMPILE_ARCHIVE=RSTALanguageSupport_${LANGUAGESUPPORT_VERSION}.zip
LANGUAGESUPPORT_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/languagesupport

#
# rtext-related module variables.
#
RTEXT_MODULES_DIR=${OUTPUT_DIR}/rtext-modules
RTEXT_BASE=http://sourceforge.net/projects/rtext/files

ICONGROUPS_PROJ_DIR=$RTEXT_MODULES_DIR/icongroups

RTEXT_SOURCE_ARCHIVE=rtext_${RTEXT_VERSION}_Source.zip
RTEXT_COMPILE_ARCHIVE=rtext_${RTEXT_VERSION}_unix_bin.tar.gz
RTEXT_PROJ_DIR=$RTEXT_MODULES_DIR/rtext

# Common and RText are both shipped in the same source jar
COMMON_SOURCE_ARCHIVE=rtext_${RTEXT_VERSION}_Source.zip
COMMON_COMPILE_ARCHIVE=rtext_${RTEXT_VERSION}_unix_bin.tar.gz
COMMON_PROJ_DIR=$RTEXT_MODULES_DIR/common

#
# Functions
#

#
# This function accepts three arguments:
#
# 1. Project Directory : The absolute path to the location in which the source code will be copied
# 2. Source Dir or Jar : The absolute path to the jar or directory containing the source.  Jars will be extracted.
# 3. Project Version   : The version to give the project (this replaces the placeholder in the pom file)
#
function mavenizemodule() {
    projDir=$1
    sourceDirOrJar=$2
    projVersion=$3

    echo "Mavenizing module: `basename ${projDir}` ${projVersion}"
    echo "build-module.sh -f=$sourceDirOrJar -v=$projVersion -o=$projDir"
    echo " "

    /bin/bash $BIN_DIR/build-module.sh -f=$sourceDirOrJar -v=$projVersion -o=$projDir
    if [ "$?" -ne "0" ]; then
        echo "Failed to mavenize module: $projDir"
        exit 1
    fi
}

#
# This function accepts 3 arguments:
#
# 1. projectName          : (e.g. rsyntaxtextarea)
# 2. artifactVersion      : (e.g. 2.0.4)
# 3. baseUri              : (e.g. http://sourceforge.net/projects/rsyntaxtextarea/files)
# 4. sourceArtifactName   s: (e.g. rsta_spellchecker_2.0.4_Source.zip)
# 5. compileArtifactName  : (e.g. rsta_spellchecker_2.0.4.zip)
#
function downloadArchives() {
    projectName=$1
    artifactVersion=$2
    baseUri=$3
    sourceArtifactName=$4
    compileArtifactName=$5

    localFile=$OFFICIAL_SOURCE_DIR/$artifactVersion/$sourceArtifactName
    downloadSite=$baseUri/$projectName/$artifactVersion/$sourceArtifactName/download
    
    if [ ! -f "$localFile" ]; then
	echo "Couldn't locate local source archive file: $localFile";
        mkdir -p "$OFFICIAL_SOURCE_DIR/$artifactVersion"
        echo "Downloading $sourceArtifactName from $downloadSite"
	    wget "$downloadSite" -O "$localFile"
        if [ "$?" -ne "0" ]; then
            echo "Unable to download $downloadSite"
	    rm -f "$localFile"
            exit 1
        fi
    fi

    localFile=$OFFICIAL_COMPILED_DIR/$artifactVersion/$compileArtifactName
    downloadSite=$baseUri/$projectName/$artifactVersion/$compileArtifactName/download

    if [ ! -f "$localFile" ]; then
	echo "Couldn't locate local compile archive file: $localFile";
        mkdir -p "$OFFICIAL_COMPILED_DIR/$artifactVersion"
        echo "Downloading $compileArtifactName from $downloadSite"
	    wget "$downloadSite" -O "$localFile"
        if [ "$?" -ne "0" ]; then
            echo "Unable to download $downloadSite"
	    rm -f "$localFile"
            exit 1
        fi
	isZipArchive=`echo "$localFile" | grep zip | wc -l`
	isTarBall=`echo "$localFile" | grep tar | wc -l`
	echo "isZipArchive : $isZipArchive"
	if [ $isZipArchive = "1" ]; then
		echo "Extracting zip archive: $localFile"
		pushd $OFFICIAL_COMPILED_DIR/$artifactVersion
		jar -xvf $localFile
		popd
	elif [ $isTarBall = "1" ]; then
		echo "Extracting zip archive: $localFile"
		pushd $OFFICIAL_COMPILED_DIR/$artifactVersion
		tar -xzvf $localFile		
	fi
	
    fi
}


# setup the directory structure that poms and source will be copied into.
rm -rf $OUTPUT_DIR
mkdir -p $AUTOCOMPLETE_PROJ_DIR
mkdir -p $LANGUAGESUPPORT_PROJ_DIR
mkdir -p $RSYNTAXTEXTAREA_PROJ_DIR
mkdir -p $SPELLCHECKER_PROJ_DIR
mkdir -p $RSTA_UI_PROJ_DIR

mkdir -p $COMMON_PROJ_DIR
mkdir -p $ICONGROUPS_PROJ_DIR
mkdir -p $RTEXT_PROJ_DIR

# copy in the pom and pom template files.
cp ${TOP_DIR}/poms/root-pom.xml                     $OUTPUT_DIR/pom.xml
cp ${TOP_DIR}/poms/rsyntaxtearea-module-pom.xml     $RSYNTAXTEXTAREA_MODULES_DIR/pom.xml
cp ${TOP_DIR}/poms/autocomplete-pom.xml.template    $AUTOCOMPLETE_PROJ_DIR/pom.xml
cp ${TOP_DIR}/poms/languagesupport-pom.xml.template $LANGUAGESUPPORT_PROJ_DIR/pom.xml
cp ${TOP_DIR}/poms/rsyntaxtextarea-pom.xml  	    $RSYNTAXTEXTAREA_PROJ_DIR/pom.xml
cp ${TOP_DIR}/poms/spellchecker-pom.xml.template    $SPELLCHECKER_PROJ_DIR/pom.xml
cp ${TOP_DIR}/poms/rstaui-pom.xml                   $RSTA_UI_PROJ_DIR/pom.xml

cp ${TOP_DIR}/poms/rtext-module-pom.xml		        $RTEXT_MODULES_DIR/pom.xml
cp ${TOP_DIR}/poms/common-pom.xml.template		    $COMMON_PROJ_DIR/pom.xml
cp ${TOP_DIR}/poms/icongroups-pom.xml		        $ICONGROUPS_PROJ_DIR/pom.xml
cp ${TOP_DIR}/poms/rtext-pom.xml.template		    $RTEXT_PROJ_DIR/pom.xml

# pull down the official source and compiled zip files from sourceforge if necessary
downloadArchives rsyntaxtextarea $RSYNTAXTEXTAREA_VERSION $RSYNTAX_BASE $RSYNTAXTEXTAREA_SOURCE_ARCHIVE $RSYNTAXTEXTAREA_COMPILE_ARCHIVE
downloadArchives autocomplete $AUTOCOMPLETE_VERSION $RSYNTAX_BASE $AUTOCOMPLETE_SOURCE_ARCHIVE $AUTOCOMPLETE_COMPILE_ARCHIVE
downloadArchives spellchecker $SPELLCHECKER_VERSION $RSYNTAX_BASE $SPELLCHECKER_SOURCE_ARCHIVE $SPELLCHECKER_COMPILE_ARCHIVE
downloadArchives rsta-ui $RSTA_UI_VERSION $RSYNTAX_BASE $RSTA_UI_SOURCE_ARCHIVE $RSTA_UI_COMPILE_ARCHIVE
downloadArchives rstalanguagesupport $LANGUAGESUPPORT_VERSION $RSYNTAX_BASE $LANGUAGESUPPORT_SOURCE_ARCHIVE $LANGUAGESUPPORT_COMPILE_ARCHIVE

# Both RText and Common modules are found in $RTEXT_COMPILE_ARCHIVE
downloadArchives rtext $RTEXT_VERSION $RTEXT_BASE $RTEXT_SOURCE_ARCHIVE $RTEXT_COMPILE_ARCHIVE

# run mavenize-module.sh on each module, giving it the location of the source archive
mavenizemodule $RSYNTAXTEXTAREA_PROJ_DIR "$OFFICIAL_SOURCE_DIR/$RSYNTAXTEXTAREA_VERSION/$RSYNTAXTEXTAREA_SOURCE_ARCHIVE" $RSYNTAXTEXTAREA_VERSION
mavenizemodule $AUTOCOMPLETE_PROJ_DIR "$OFFICIAL_SOURCE_DIR/$AUTOCOMPLETE_VERSION/$AUTOCOMPLETE_SOURCE_ARCHIVE" $AUTOCOMPLETE_VERSION
mavenizemodule $SPELLCHECKER_PROJ_DIR "$OFFICIAL_SOURCE_DIR/$SPELLCHECKER_VERSION/$SPELLCHECKER_SOURCE_ARCHIVE" $SPELLCHECKER_VERSION
mavenizemodule $RSTA_UI_PROJ_DIR "$OFFICIAL_SOURCE_DIR/$RSTA_UI_VERSION/$RSTA_UI_SOURCE_ARCHIVE" $RSTA_UI_VERSION
mavenizemodule $LANGUAGESUPPORT_PROJ_DIR "$OFFICIAL_SOURCE_DIR/language-support/$LANGUAGESUPPORT_VERSION" "r${LANGUAGESUPPORT_VERSION}"
mavenizemodule $COMMON_PROJ_DIR "$OFFICIAL_SOURCE_DIR/$RTEXTCOMMON_VERSION/$COMMON_SOURCE_ARCHIVE" $RTEXTCOMMON_VERSION
mavenizemodule $RTEXT_PROJ_DIR "$OFFICIAL_SOURCE_DIR/$RTEXT_VERSION/$RTEXT_SOURCE_ARCHIVE" $RTEXT_VERSION

exit 0
# build each module in dependency order and compare the maven-built jar to the official jar.
# Fail fast if there are significant differences in any artifact.
# depedency order is: rsyntaxtextarea, autocomplete, spellchecker, languagesuppport, rtext-common, rtext

cd ${OUTPUT_DIR}
mvn clean source:jar javadoc:jar install

/bin/bash $BIN_DIR/prepare-bundle.sh $RSYNTAXTEXTAREA_PROJ_DIR/target
/bin/bash $BIN_DIR/prepare-bundle.sh $AUTOCOMPLETE_PROJ_DIR/target
/bin/bash $BIN_DIR/prepare-bundle.sh $SPELLCHECKER_PROJ_DIR/target
/bin/bash $BIN_DIR/prepare-bundle.sh $RSTA_UI_PROJ_DIR/target
/bin/bash $BIN_DIR/prepare-bundle.sh $LANGUAGESUPPORT_PROJ_DIR/target
/bin/bash $BIN_DIR/prepare-bundle.sh $COMMON_PROJ_DIR/target
/bin/bash $BIN_DIR/prepare-bundle.sh $RTEXT_PROJ_DIR/target
/bin/bash $BIN_DIR/prepare-bundle.sh $ICONGROUPS_PROJ_DIR/target


#compj $AUTOCOMPLETE_PROJ_DIR/target/autocomplete-${AUTOCOMPLETE_VERSION}.jar $OFFICIAL_COMPILED_DIR/$AUTOCOMPLETE_VERSION/autocomplete.jar
#compj $RSYNTAXTEXTAREA_PROJ_DIR/target/rsyntaxtextarea-${RSYNTAXTEXTAREA_VERSION}.jar  $OFFICIAL_COMPILED_DIR/$RSYNTAXTEXTAREA_VERSION/rsyntaxtextarea.jar
#compj $SPELLCHECKER_PROJ_DIR/target/spellchecker-${SPELLCHECKER_VERSION}.jar $OFFICIAL_COMPILED_DIR/$SPELLCHECKER_VERSION/rsta_spellchecker.jar
#compj $RSTA_UI_PROJ_DIR/target/rstaui-${RSTA_UI_VERSION}.jar $OFFICIAL_COMPILED_DIR/$RSTA_UI_VERSION/rstaui.jar
#compj $RTEXT_PROJ_DIR/target/rtext-${RTEXT_VERSION}.jar $OFFICIAL_COMPILED_DIR/$RTEXT_VERSION/rtext/RText.jar
#compj $COMMON_PROJ_DIR/target/common-${RTEXTCOMMON_VERSION}.jar $OFFICIAL_COMPILED_DIR/$RTEXTCOMMON_VERSION/rtext/fife.common.jar
#compj $LANGUAGESUPPORT_PROJ_DIR/target/languagesupport-r${LANGUAGESUPPORT_VERSION}.jar $OFFICIAL_COMPILED_DIR/$RTEXTCOMMON_VERSION/rtext/plugins/language_support.jar
##compj $ICONGROUPS_PROJ_DIR/target/

echo "To use meld, execute the following commands (The official released jar is the one without a version): "

echo "meld /tmp/autocomplete-${AUTOCOMPLETE_VERSION}.jar.extracted /tmp/autocomplete.jar.extracted"
echo "meld /tmp/rsyntaxtextarea-${RSYNTAXTEXTAREA_VERSION}.jar.extracted  /tmp/rsyntaxtextarea.jar.extracted"
echo "meld /tmp/spellchecker-${SPELLCHECKER_VERSION}.jar.extracted /tmp/rsta_spellchecker.jar.extracted"
echo "meld /tmp/rstaui-${RSTA_UI_VERSION}.jar.extracted /tmp/rstaui.jar.extracted"
echo "meld /tmp/rtext-${RTEXT_VERSION}.jar.extracted /tmp/RText.jar.extracted"
echo "meld /tmp/common-${RTEXTCOMMON_VERSION}.jar.extracted /tmp/fife.common.jar.extracted"
echo "meld /tmp/languagesupport-r${LANGUAGESUPPORT_VERSION}.jar.extracted /tmp/language_support.jar.extracted"

exit 0