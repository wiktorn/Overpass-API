#!/bin/bash
set -e -o pipefail

DISPATCHER_ARGS=("--osm-base" "--db-dir=/db/db")
if [[ "${OVERPASS_META}" == "attic" ]]; then
	DISPATCHER_ARGS+=("--attic")
elif [[ "${OVERPASS_META}" == "yes" ]]; then
	DISPATCHER_ARGS+=("--meta")
fi

if [[ -n ${OVERPASS_RATE_LIMIT} ]]; then
	DISPATCHER_ARGS+=("--rate-limit=${OVERPASS_RATE_LIMIT}")
fi

if [[ -n ${OVERPASS_TIME} ]]; then
	DISPATCHER_ARGS+=("--time=${OVERPASS_TIME}")
fi
if [[ -n ${OVERPASS_SPACE} ]]; then
	DISPATCHER_ARGS+=("--space=${OVERPASS_SPACE}")
fi

find /db/db -type s -print0 | xargs -0 --no-run-if-empty rm && /app/bin/dispatcher "${DISPATCHER_ARGS[@]}"
