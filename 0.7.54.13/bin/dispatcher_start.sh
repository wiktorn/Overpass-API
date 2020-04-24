#!/bin/bash
set -e -o pipefail

DISPATCHER_ARGS=("--osm-base" "--db-dir=/db/db")
if [[ "${OVERPASS_META}" == "attic" ]] ; then
  DISPATCHER_ARGS+=("--attic")
elif [[ "${OVERPASS_META}" == "yes" ]] ; then
  DISPATCHER_ARGS+=("--meta")
fi

if [[ -v ${OVERPASS_RATE_LIMIT} ]] ; then
  DISPATCHER_ARGS+=("--rate-limit=${OVERPASS_RATE_LIMIT}")
fi

find /db/db -type s -print0 | xargs -0 --no-run-if-empty rm && /app/bin/dispatcher "${DISPATCHER_ARGS[@]}"
