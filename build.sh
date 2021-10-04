#!/bin/sh

set -e

case "$1" in
  "build")
    python update.py
    for i in `ls -d 0.*` ; do
      docker build -t wiktorn/overpass-api:$i -f $i/Dockerfile .
    done
    for i in `ls -d 0.* | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -n 1` ; do
      docker tag wiktorn/overpass-api:$i wiktorn/overpass-api:latest
    done
    ;;
  "push")
    for i in `ls -d 0.*` ; do
      docker push wiktorn/overpass-api:$i
    done
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


