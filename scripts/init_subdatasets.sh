#!/bin/bash

# this script is meant to be used with 'datalad run'

for i in "$@"
do
	case ${i} in
		--version=*)
		VERSION="${i#*=}"
		echo "VERSION = [${VERSION}]"
		if [ ! $VERSION = "1.2" ] && [ ! $VERSION = "2.0" ]
		then
			>&2 echo --version option must be either 1.2 or 2.0
			unset VERSION
		fi
		;;
		*)
		>&2 echo Unknown option [${i}]
		exit 1
		;;
	esac
done

if [ -z "$VERSION" ]
then
	>&2 echo --version option must be either 1.2 or 2.0
	>&2 echo missing --version option
	exit 1
fi

mkdir -p $VERSION/


pip install -r scripts/requirements_init_subdatasets.txt --upgrade
if [ $? -ne 0 ]; then
   echo "Failed to install requirements: pip install: $?"
   return $?
fi

REPO_NAME=
REPO_EXT=

if [ $VERSION = "1.2" ]
then
        YEARS="1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017"
	REPO_NAME=nwm-archive
	REPO_EXT=
elif [ $VERSION = "2.0" ]
then
        YEARS="1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018"
	REPO_NAME=noaa-nwm-retro-v2.0-pds
	REPO_EXT=long_range/
fi

for year in ${YEARS}
do
	datalad create -d . ${VERSION}/${year}
done

for year in ${YEARS}
do
	files=`aws s3 ls s3://${REPO_NAME}/${REPO_EXT}${year}/ --no-sign-request | grep -o "${year}[0-9]\{8\}\..*"`
	cd ${VERSION}/${year}/
	for file in ${files[*]}
	do
		echo "http://${REPO_NAME}.s3.amazonaws.com/${REPO_EXT}${year}/${file} ${file}" | git-annex addurl --fast --raw --batch --with-files
	done
	cd ../..
done
