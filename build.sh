#!/bin/sh

for i in `ls -d 0.*` ; do  docker build -t wiktorn/overpass-api:$i -f $i/Dockerfile . ; docker push wiktorn/overpass-api:$i ; done
for i in `ls -d 0.* | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -n 1` ; do (docker tag wiktorn/overpass-api:$i wiktorn/overpass-api:latest ; docker push wiktorn/overpass-api:latest ) ; done

