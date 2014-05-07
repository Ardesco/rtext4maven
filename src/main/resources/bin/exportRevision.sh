#! /bin/bash

#
# This script is a helper that will export the source for the languagesupport module.  This is the only
# module that is not released by the RSyntaxTextArea developers.  This script accepts a single argument
# which is the revision number.  In order to decide which revision number to use, you must look at the 
# release dates on the downstream dependencies (rtext and rtext-common).  Pick the svn revision that was
# the closest without going beyond the earliest release data of these two modules.  The svn repo for 
# the languagesupport project is found here:
#
# http://svn.fifesoft.com/viewvc-1.0.5/bin/cgi/viewvc.cgi/RSTALanguageSupport/trunk/?root=RSyntaxTextArea
#  
# A handy command that dumps all revisions and their date in descending order is:
#
# svn log http://svn.fifesoft.com/svn/RSyntaxTextArea/RSTALanguageSupport/trunk | egrep "^r[0-9]+.*"
#

revision=$1

if [ "" == "$revision" ]; then
	echo "Usage: exportRevision.sh <revision number>"
	exit 1
fi

exportDir=svn-trunk-r${revision}

echo "Checking out source using revision $revision into the directory: `pwd`/$exportDir"

rm -rf $exportDir
mkdir $exportDir

pushd $exportDir

svn export --force -r $revision http://svn.fifesoft.com/svn/RSyntaxTextArea/RSTALanguageSupport/trunk .  > svn-export.log 2>&1

echo "Export is complete."

popd
