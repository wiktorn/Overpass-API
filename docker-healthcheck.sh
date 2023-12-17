#!/bin/bash

set -e -o pipefail

NODE_ID=1

# if we allow duplicate queries, the healthcheck will fail because it always fetches node id 1
# if that is the case (default), we query a random node
if [[ ! -n ${OVERPASS_ALLOW_DUPLICATE_QUERIES} || ${OVERPASS_ALLOW_DUPLICATE_QUERIES} == "no" ]]; then
  NODE_ID=$(shuf -i 1-10000000 -n 1)
fi

OVERPASS_HEALTHCHECK=${OVERPASS_HEALTHCHECK:-'curl --noproxy "*" -qf "http://localhost/api/interpreter?data=\[out:json\];node(${NODE_ID});out;" | jq ".generator" |grep -q Overpass || exit 1'}

eval "${OVERPASS_HEALTHCHECK}"
