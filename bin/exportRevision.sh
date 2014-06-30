#!/usr/bin/env bash

#
# This script is a helper that will export the source for the languagesupport module.  This is the only
# module that is not released by the RSyntaxTextArea developers.  This script accepts two arguments:
#
# 1. git revision number
# 2. export directory (Optional: will create an 'exportDirectoy' in the current folder by default
#  
# In order to decide which revision number to use, you must look at the 
# release dates on the downstream dependencies (rtext and rtext-common).  Pick the git revision that was
# the closest without going beyond the earliest release data of these two modules.  The git repo for 
# the languagesupport project is found here:
#
# https://github.com/bobbylight/RSTALanguageSupport
#  

function usage(){
    echo -e "\nYou must specify a git revision e.g. './`basename $0` -r=8324c615b702e5dab0b3979a4fb3639a7c17bbdb'"
    echo -e "\n*** Available Parameters ***\n"
    echo -e "-r | --revision \t\t\t set the git revision"
    echo -e "-e | --exportDir \t\t\t set the export directory\n"
    echo -e "-h | --help \t\t\t Show this help!"
    exit 1
}

for _argument in "$@"
do
    case ${_argument} in
        -r=*|--revision=*)
        _revision="${_argument#*=}"
        ;;
        -e=*|--exportDir=*)
        _exportDir="${_argument#*=}"
        ;;
        -h|--help)
        usage
        ;;
    esac
done

if [ "" == "$_revision" ]; then
    usage
fi

if [ "" == "$_exportDir" ]; then
	_exportDir="exportDirectory"
fi

echo "Checking out source using revision $_revision into the directory: `pwd`/$_exportDir"

if [ -d "$_exportDir" ]; then
    rm -rf $_exportDir
fi
mkdir -p $_exportDir

pushd $_exportDir > /dev/null
git clone -q https://github.com/bobbylight/RSTALanguageSupport . > git_export.log 2>&1
git checkout $_revision >> git_export.log 2>&1
git reset --hard >> git_export.log 2>&1
popd > /dev/null

echo "Export is complete."
exit 0