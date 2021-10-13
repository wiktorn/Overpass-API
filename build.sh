#!/bin/bash

set -e

case "$1" in
"build")
	python update.py

	# docker build
	find . -maxdepth 1 -type d -name '0.*' -exec sh -c 'docker build -t wiktorn/overpass-api:$(basename "$1") -f "$1"/Dockerfile .' sh {} \;

	# docker tag
	while IFS= read -r -d '' file; do
		docker tag "wiktorn/overpass-api:$(basename "$file")" wiktorn/overpass-api:latest
	done < <(find . -maxdepth 1 -type d -regex '\./[0-9]\.[0-9]\.[0-9]*' -print0 | sort -nz | tail -z -n 1)
	;;
"push")
	# docker push
	find . -maxdepth 1 -type d -name '0.*' -exec sh -c 'docker push "wiktorn/overpass-api:$(basename "$1")"' sh {} \;
	docker push wiktorn/overpass-api:latest
	;;
"$1")
	echo "Invalid argument $1"
	echo "Valid arguments:"
	echo "$0 build - to build docker images"
	echo "$0 push - to push built images to docker hub"
	exit 1
	;;
esac
