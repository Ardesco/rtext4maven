#! /bin/bash

#
# This script is a helper that will export the source for the languagesupport module.  This is the only
# module that is not released by the RSyntaxTextArea developers.  This script expects two arguments:
#
# 1. git revision number
# 2. export directory
#  
# In order to decide which revision number to use, you must look at the 
# release dates on the downstream dependencies (rtext and rtext-common).  Pick the git revision that was
# the closest without going beyond the earliest release data of these two modules.  The git repo for 
# the languagesupport project is found here:
#
# https://github.com/bobbylight/RSTALanguageSupport
#  

revision=$1
exportDir=$2

if [ "" == "$revision" -o "" == "$exportDir" ]; then
	echo "Usage: exportRevision.sh <revision number> <export dir>"
	exit 1
fi

echo "Checking out source using revision $revision into the directory: `pwd`/$exportDir"

rm -rf $exportDir
mkdir -p $exportDir

git clone -q https://github.com/bobbylight/RSTALanguageSupport $exportDir > git-export.log 2>&1

pushd $exportDir > /dev/null
git checkout $revision >> git-export.log 2>&1
popd > /dev/null

echo "Export is complete."

