#!/bin/bash

set -e

IMAGE=wiktorn/overpass-api

case "$1" in
"build")
	versions=$(python update.py)

	for version in $versions; do
		docker build --build-arg "OVERPASS_VERSION=${version}" -t "${IMAGE}:${version}" .
	done

	latest=$(echo "$versions" | sort -V | tail -n 1)
	docker tag "${IMAGE}:${latest}" "${IMAGE}:latest"
	;;

"push")
	versions=$(python update.py)

	for version in $versions; do
		docker push "${IMAGE}:${version}"
	done
	docker push "${IMAGE}:latest"
	;;

"$1")
	echo "Invalid argument $1"
	echo "Valid arguments:"
	echo "$0 build - to build docker images"
	echo "$0 push - to push built images to docker hub"
	exit 1
	;;
esac
