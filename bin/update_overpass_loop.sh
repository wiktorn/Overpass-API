#!/usr/bin/env sh

OVERPASS_UPDATE_SLEEP=${OVERPASS_UPDATE_SLEEP:-60}
set +e
while `true` ;  do
    /app/bin/update_overpass.sh
    sleep "${OVERPASS_UPDATE_SLEEP}"
done
