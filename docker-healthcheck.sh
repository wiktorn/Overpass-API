#!/bin/bash

set -e -o pipefail

OVERPASS_HEALTHCHECK=${OVERPASS_HEALTHCHECK:-'curl -qf "http://localhost/api/interpreter?data=\[out:json\];node(1);out;" | jq ".generator" |grep -q Overpass || exit 1'}

eval "${OVERPASS_HEALTHCHECK}"
