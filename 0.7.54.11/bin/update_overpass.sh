#!/usr/bin/env sh

(
    set -e

    if [ "x$OVERPASS_META" = "xattic" ] ; then
        META="--keep-attic"
    elif [ "x$OVERPASS_META" = "xyes" ] ; then
        META="--meta"
    else
        META=""
    fi

    while `true` ; do
        (
            ! /app/venv/bin/pyosmium-get-changes --server $OVERPASS_DIFF_URL -o /db/changes.osm -f /db/replicate_id
            OSMIUM_STATUS=$?
            if [ $OSMIUM_STATUS -eq 1 ]; then
                echo "There are still some updates remainging"
            fi
            if [ $OSMIUM_STATUS -eq 2 ]; then
                echo "Failure downloading updates"
                exit 0
            fi
            (cat /db/changes.osm | /app/bin/update_database --db-dir=/db/db $META --compression-method=$OVERPASS_COMPRESSION) 2>&1 | tee -a /db/changes.log
            rm /db/changes.osm
        )
        sleep 60
    done
) 2>&1 | tee -a /db/changes.log