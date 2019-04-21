#!/usr/bin/env sh

set -e

if [[ "$OVERPASS_META" == "attic" ]] ; then
    META="--keep-attic"
else
    META="--meta"
fi

while `true` ; do
    /app/venv/bin/pyosmium-get-changes --server $OVERPASS_DIFF_URL -o /db/changes.osm -f /db/replicate_id \
        && cat /db/changes.osm | /app/bin/update_database --db-dir=/db/db $META --compression-method=$OVERPASS_COMPRESSION \
        || rm -f /db/changes.osm
    rm -f /db/changes.osm
    sleep 60
done
