#!/usr/bin/env sh

set +e
while `true` ;  do
    /app/bin/update_overpass.sh
    sleep 60
done
