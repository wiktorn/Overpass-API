#!/bin/bash
set -e -o pipefail

if [[ "$1" == "--areas" ]]; then
	DISPATCHER_ARGS=("--areas" "--db-dir=/db/db")
	SOCKET_PATTERN="*areas*"
	SHM_PATTERN="osm3s*areas"
else
	DISPATCHER_ARGS=("--osm-base" "--db-dir=/db/db")
	SOCKET_PATTERN="*osm_base*"
	SHM_PATTERN="osm3s*osm_base"
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
fi

if [[ -n ${OVERPASS_ALLOW_DUPLICATE_QUERIES} ]]; then
	DISPATCHER_ARGS+=("--allow-duplicate-queries=${OVERPASS_ALLOW_DUPLICATE_QUERIES}")
fi

find /dev/shm -maxdepth 1 -name "${SHM_PATTERN}" -print0 | xargs -0 --no-run-if-empty rm -f
find /db/db -maxdepth 1 -type s -name "${SOCKET_PATTERN}" -print0 | xargs -0 --no-run-if-empty rm -f
exec /app/bin/dispatcher "${DISPATCHER_ARGS[@]}"
