#!/bin/bash

# this script is meant to be used with 'datalad run'

pip install -r scripts/requirements_extract_max_streamflow.txt
ERR=$?
if [ $ERR -ne 0 ]; then
   echo "Failed to install requirements: pip install: $ERR"
   exit $ERR
fi

datalad install 199*/ 200*/ 201*/

mkdir -p stats/

jug status -- scripts/extract_max_streamflow.py --output=stats/ --drop-after
jug execute -- scripts/extract_max_streamflow.py --output=stats/ --drop-after 1>> extract_max_streamflow.out 2>> extract_max_streamflow.err
