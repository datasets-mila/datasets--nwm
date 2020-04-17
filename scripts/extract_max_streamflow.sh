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

pip install -r scripts/requirements_extract_max_streamflow.txt
ERR=$?
if [ $ERR -ne 0 ]; then
   echo "Failed to install requirements: pip install: $ERR"
   exit $ERR
fi

datalad install $VERSION/199*/ $VERSION/200*/ $VERSION/201*/

mkdir -p $VERSION/stats/

jug status -- scripts/extract_max_streamflow.py $VERSION --output=$VERSION/stats/ --drop-after
jug execute -- scripts/extract_max_streamflow.py $VERSION --output=$VERSION/stats/ --drop-after \
	1>> extract_max_streamflow.out 2>> extract_max_streamflow.err
