#! /bin/bash

export RSYNTAXTEXTAREA_VERSION=2.0.4.1
export AUTOCOMPLETE_VERSION=2.0.4
export SPELLCHECKER_VERSION=2.0.4
export RSTA_UI_VERSION=2.0.4
export RTEXT_VERSION=2.0.4
export RTEXTCOMMON_VERSION=2.0.4
# See comments at the top of exportRevision.sh to determine what this should be set to.
export LANGUAGESUPPORT_VERSION=655

#
# rsyntaxtextarea-related module variables.
#
RSYNTAXTEXTAREA_MODULES_DIR=${project.build.directory}/output/rsyntaxtextarea-modules

RSYNTAXTEXTAREA_SOURCE_FILE=rsyntaxtextarea_${RSYNTAXTEXTAREA_VERSION}_Source.zip
RSYNTAXTEXTAREA_DOWNLOAD_SITE=http://sourceforge.net/projects/rsyntaxtextarea/files/rsyntaxtextarea/$RSYNTAXTEXTAREA_VERSION/$RSYNTAXTEXTAREA_SOURCE_FILE/download
RSYNTAXTEXTAREA_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/rsyntaxtextarea

AUTOCOMPLETE_SOURCE_FILE=autocomplete_${AUTOCOMPLETE_VERSION}_Source.zip
AUTOCOMPLETE_DOWNLOAD_SITE=http://sourceforge.net/projects/rsyntaxtextarea/files/autocomplete/$AUTOCOMPLETE_VERSION/$AUTOCOMPLETE_SOURCE_FILE/download
AUTOCOMPLETE_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/autocomplete

SPELLCHECKER_SOURCE_FILE=rsta_spellchecker_${SPELLCHECKER_VERSION}_Source.zip
SPELLCHECKER_DOWNLOAD_SITE=http://sourceforge.net/projects/rsyntaxtextarea/files/spellchecker/$SPELLCHECKER_VERSION/$SPELLCHECKER_SOURCE_FILE/download
SPELLCHECKER_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/spellchecker

RSTA_UI_SOURCE_FILE=rstaui_2.0.4_Source.zip
RSTA_UI_DOWNLOAD_SITE=http://sourceforge.net/projects/rsyntaxtextarea/files/rsta-ui/${RSTA_UI_VERSION}/rstaui_${RSTA_UI_VERSION}_Source.zip/download
RSTA_UI_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/rstaui

# Unlike the rest of the rsyntaxtextarea modules, languagesupport isn't "officially" released.
LANGUAGESUPPORT_PROJ_DIR=$RSYNTAXTEXTAREA_MODULES_DIR/languagesupport

#
# rtext-related module variables.
#
RTEXT_MODULES_DIR=${project.build.directory}/output/rtext-modules

ICONGROUPS_PROJ_DIR=$RTEXT_MODULES_DIR/icongroups

RTEXT_SOURCE_FILE=rtext_${RTEXT_VERSION}_Source.zip
RTEXT_DOWNLOAD_SITE=http://sourceforge.net/projects/rtext/files/rtext/$RTEXT_VERSION/$RTEXT_SOURCE_FILE/download
RTEXT_PROJ_DIR=$RTEXT_MODULES_DIR/rtext

# Common and RText are both shipped in the same source jar
COMMON_SOURCE_FILE=rtext_${RTEXT_VERSION}_Source.zip
COMMON_DOWNLOAD_SITE=http://sourceforge.net/projects/rtext/files/rtext/$RTEXT_VERSION/$RTEXT_SOURCE_FILE/download
COMMON_PROJ_DIR=$RTEXT_MODULES_DIR/common


TOP_DIR=${basedir}
BIN_DIR=$TOP_DIR/target/classes/bin
SOURCE_DIR=$TOP_DIR/official-jars/source


#
# Functions
#
function mavenizemodule() {
    projDir=$1
    sourceDirOrJar=$2
    projVersion=$3
    
    echo "Mavenizing module: projDir=${projDir} sourceDirOrJar=${sourceDirOrJar} projVersion=${projVersion}"

    cd $projDir
    /bin/bash $BIN_DIR/mavenize-module.sh $sourceDirOrJar $projVersion  
    if [ "$?" -ne "0" ]; then
        echo "Failed to mavenize module: $projDir"
        exit 1
    fi
}



# setup the directory structure that poms and source will be copied into.
rm -rf ${project.build.directory}/output
mkdir -p $AUTOCOMPLETE_PROJ_DIR
mkdir -p $LANGUAGESUPPORT_PROJ_DIR
mkdir -p $RSYNTAXTEXTAREA_PROJ_DIR
mkdir -p $SPELLCHECKER_PROJ_DIR
mkdir -p $RSTA_UI_PROJ_DIR

mkdir -p $COMMON_PROJ_DIR
mkdir -p $ICONGROUPS_PROJ_DIR
mkdir -p $RTEXT_PROJ_DIR

# copy in the pom and pom template files.
cp poms/root-pom.xml			  ${project.build.directory}/output/pom.xml
cp poms/rsyntaxtearea-module-pom.xml      $RSYNTAXTEXTAREA_MODULES_DIR/pom.xml
cp poms/autocomplete-pom.xml.template     $AUTOCOMPLETE_PROJ_DIR/pom.xml
cp poms/languagesupport-pom.xml.template  $LANGUAGESUPPORT_PROJ_DIR/pom.xml
cp poms/rsyntaxtextarea-pom.xml  	  $RSYNTAXTEXTAREA_PROJ_DIR/pom.xml
cp poms/spellchecker-pom.xml.template     $SPELLCHECKER_PROJ_DIR/pom.xml
cp poms/rstaui-pom.xml                    $RSTA_UI_PROJ_DIR/pom.xml

cp poms/rtext-module-pom.xml		  $RTEXT_MODULES_DIR/pom.xml
cp poms/common-pom.xml.template		  $COMMON_PROJ_DIR/pom.xml
cp poms/icongroups-pom.xml		  $ICONGROUPS_PROJ_DIR/pom.xml
cp poms/rtext-pom.xml.template		  $RTEXT_PROJ_DIR/pom.xml

# pull down source zip files from sourceforge if necessary
if [ ! -f "$SOURCE_DIR/$RSYNTAXTEXTAREA_VERSION/$RSYNTAXTEXTAREA_SOURCE_FILE" ]; then
    mkdir -p "$SOURCE_DIR/$RSYNTAXTEXTAREA_VERSION"
	wget "$RSYNTAXTEXTAREA_DOWNLOAD_SITE" -O "$SOURCE_DIR/$RSYNTAXTEXTAREA_VERSION/$RSYNTAXTEXTAREA_SOURCE_FILE"
fi
if [ ! -f "$SOURCE_DIR/$AUTOCOMPLETE_VERSION/$AUTOCOMPLETE_SOURCE_FILE" ]; then
    mkdir -p "$SOURCE_DIR/$AUTOCOMPLETE_VERSION"
    wget "$AUTOCOMPLETE_DOWNLOAD_SITE" -O "$SOURCE_DIR/$AUTOCOMPLETE_VERSION/$AUTOCOMPLETE_SOURCE_FILE"
fi
if [ ! -f "$SOURCE_DIR/$SPELLCHECKER_VERSION/$SPELLCHECKER_SOURCE_FILE" ]; then
    mkdir -p "$SOURCE_DIR/$SPELLCHECKER_VERSION"
    wget "$SPELLCHECKER_DOWNLOAD_SITE" -O "$SOURCE_DIR/$SPELLCHECKER_VERSION/$SPELLCHECKER_SOURCE_FILE"
fi
if [ ! -f "$SOURCE_DIR/$RSTA_UI_VERSION/$RSTA_UI_SOURCE_FILE" ]; then
    mkdir -p "$SOURCE_DIR/$RSTA_UI_VERSION"
    wget "$RSTA_UI_DOWNLOAD_SITE" -O "$SOURCE_DIR/$RSTA_UI_VERSION/$RSTA_UI_SOURCE_FILE"
fi
if [ ! -f "$SOURCE_DIR/$RTEXT_VERSION/$RTEXT_SOURCE_FILE" ]; then
    mkdir -p "$SOURCE_DIR/$RTEXT_VERSION"
    wget "$RTEXT_DOWNLOAD_SITE" -O "$SOURCE_DIR/$RTEXT_VERSION/$RTEXT_SOURCE_FILE"
fi
if [ ! -f "$SOURCE_DIR/$RTEXTCOMMON_VERSION/$COMMON_SOURCE_FILE" ]; then
    mkdir -p "$SOURCE_DIR/$RTEXTCOMMON_VERSION"
    wget "$COMMON_DOWNLOAD_SITE" -O "$SOURCE_DIR/$RTEXTCOMMON_VERSION/$COMMON_SOURCE_FILE"
fi

# languagesupport module isn't released, so we need to export it from svn.
if [ ! -d "$SOURCE_DIR/$LANGUAGESUPPORT_VERSION" ]; then
    mkdir -p "$SOURCE_DIR/$LANGUAGESUPPORT_VERSION"
    cd "$SOURCE_DIR/$LANGUAGESUPPORT_VERSION"
    /bin/bash $BIN_DIR/exportRevision.sh $LANGUAGESUPPORT_VERSION
fi

# run mavenize-module.sh on each module, giving it the location of the source archive
mavenizemodule $RSYNTAXTEXTAREA_PROJ_DIR "$SOURCE_DIR/$RSYNTAXTEXTAREA_VERSION/$RSYNTAXTEXTAREA_SOURCE_FILE" $RSYNTAXTEXTAREA_VERSION

mavenizemodule $AUTOCOMPLETE_PROJ_DIR "$SOURCE_DIR/$AUTOCOMPLETE_VERSION/$AUTOCOMPLETE_SOURCE_FILE" $AUTOCOMPLETE_VERSION

mavenizemodule $SPELLCHECKER_PROJ_DIR "$SOURCE_DIR/$SPELLCHECKER_VERSION/$SPELLCHECKER_SOURCE_FILE" $SPELLCHECKER_VERSION   

mavenizemodule $RSTA_UI_PROJ_DIR "$SOURCE_DIR/$RSTA_UI_VERSION/$RSTA_UI_SOURCE_FILE" $RSTA_UI_VERSION 

mavenizemodule $LANGUAGESUPPORT_PROJ_DIR "$SOURCE_DIR/$LANGUAGESUPPORT_VERSION/svn-trunk-r${LANGUAGESUPPORT_VERSION}" "r${LANGUAGESUPPORT_VERSION}"

mavenizemodule $COMMON_PROJ_DIR "$SOURCE_DIR/$RTEXTCOMMON_VERSION/$COMMON_SOURCE_FILE" $RTEXTCOMMON_VERSION

mavenizemodule $RTEXT_PROJ_DIR "$SOURCE_DIR/$RTEXT_VERSION/$RTEXT_SOURCE_FILE" $RTEXT_VERSION


# build each module in dependency order and compare the maven-built jar to the official jar.
# Fail fast if there are significant differences in any artifact.
# depedency order is: rsyntaxtextarea, autocomplete, spellchecker, languagesuppport, rtext-common, rtext

exit 0
