#!/bin/bash
set -e -o pipefail

if [[ $OVERPASS_META == 'yes' ]] ; then 
  META_ARG='--meta' 
elif [[ $OVERPASS_META == 'attic' ]] ; then 
  META_ARG='--attic' 
else 
  META_ARG_='' 
fi 

find /db/db -type s -print0 | xargs -0 --no-run-if-empty rm && /app/bin/dispatcher --osm-base "${META_ARG}" --db-dir=/db/db

