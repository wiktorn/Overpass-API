#!/usr/bin/env sh

OVERPASS_UPDATE_SLEEP=${OVERPASS_UPDATE_SLEEP:-60}
set +e
while true; do
	if [ -n "$OVERPASS_DIFF_URL" ]; then
		/app/bin/update_overpass.sh
	fi
	sleep "${OVERPASS_UPDATE_SLEEP}"
done
