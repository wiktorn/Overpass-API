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

    if [ ! -d /db/diffs ] ; then
        mkdir /db/diffs
    fi

    while `true` ; do
        (
            if [ ! -e  /db/diffs/changes.osm ] ; then
                ! /app/venv/bin/pyosmium-get-changes --server $OVERPASS_DIFF_URL -o /db/diffs/changes.osm -f /db/replicate_id
                OSMIUM_STATUS=$?
                if [ $OSMIUM_STATUS -eq 1 ]; then
                    echo "There are still some updates remainging"
                fi
                if [ $OSMIUM_STATUS -eq 2 ]; then
                    echo "Failure downloading updates"
                    exit 0
                fi
            else
                echo "/db/diffs/changes.osm exists. Trying to apply again."
            fi
            if /app/bin/dispatcher --show-dir ; then
                DB_DIR=""
            else
                DB_DIR="--db-dir=/db/db"
            fi
            /app/bin/update_from_dir --osc-dir=/db/diffs/ $META || /app/bin/update_from_dir --osc-dir=/db/diffs/ $META $DB_DIR
            rm /db/diffs/changes.osm
        )
        sleep 60
    done
) 2>&1 | tee -a /db/changes.log