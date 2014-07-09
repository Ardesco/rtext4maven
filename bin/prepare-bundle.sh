#!/usr/bin/env bash

# This script prepares a "bundle" for a project, given the specified target folder as the first argument.
# This will remove gpg file (*.asc) generated by the maven-gpg-plugin as from time to time these files
# are corrupted.  This will use the gpg command directly to produce the files then use gpg to verify them.

function usage(){
    echo -e "\nYou must specify a target folder e.g. './`basename $0` -t=rSyntaxArea/target'"
    echo -e "\n*** Available Parameters ***\n"
    echo -e "-t | --targetFolder \t\t\t set folder to create a bundle from"
    echo -e "-h | --help \t\t\t Show this help!"
    exit 1
}

for _argument in "$@"
do
    case ${_argument} in
        -t=*|--targetFolder=*)
        _targetFolder="${_argument#*=}"
        ;;
        -h|--help)
        usage
        ;;
    esac
done

_targetFolder=$1

if [ "" == "$GPGPASSPHRASE" ]; then
	echo "Environment variable GPGPASSPHRASE must be defined"
	exit 1
fi

pushd $_targetFolder > /dev/null
rm -f *.asc
#TODO work out what the hell this was reading, there is no.pom file in the targetFolder...
bundleJarName=`ls | grep pom | sed 's/.pom//'`-bundle.jar

for file in *.jar *.pom
do
	gpg -ab --passphrase $GPGPASSPHRASE $file
done

for file in *.asc
do 
	gpg --verify $file
	if [ "$?" != "0" ]; then
		echo "Signature couldn't be verified."
		exit 1
	fi    
done

jar -cvf $bundleJarName *.jar *.pom *.asc
popd > /dev/null