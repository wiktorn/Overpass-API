#!/bin/bash

set -e

IMAGE=wiktorn/overpass-api
VERSIONS=$(python update.py)

case "$1" in
"build")
	for version in $VERSIONS; do
		docker build --build-arg "OVERPASS_VERSION=${version}" -t "${IMAGE}:${version}" .
	done

	latest=$(echo "$VERSIONS" | sort -V | tail -n 1)
	docker tag "${IMAGE}:${latest}" "${IMAGE}:latest"
	;;

"push")
	for version in $VERSIONS; do
		docker push "${IMAGE}:${version}"
	done
	docker push "${IMAGE}:latest"
	;;

"$1")
	echo "Invalid argument $1"
	echo "Valid arguments:"
	echo "$0 build - to build Docker images"
	echo "$0 push - to push built images to Docker Hub"
	exit 1
	;;
esac
