#!/usr/bin/env sh

DIFF_FILE=/db/diffs/changes.osm

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
        ! (
            if [ ! -e  /db/diffs/changes.osm ] ; then
                ! /app/venv/bin/pyosmium-get-changes --server $OVERPASS_DIFF_URL -o $DIFF_FILE -f /db/replicate_id
                OSMIUM_STATUS=$?
                if [ $OSMIUM_STATUS -eq 1 ]; then
                    echo "There are still some updates remaining"
                fi
                if [ $OSMIUM_STATUS -eq 2 ]; then
                    echo "Failure downloading updates"
                    exit 3
                fi
            else
                echo "/db/diffs/changes.osm exists. Trying to apply again."
            fi
            if /app/bin/dispatcher --show-dir ; then
                DB_DIR=""
            else
                DB_DIR="--db-dir=/db/db"
            fi
            (cat $DIFF_FILE | /app/bin/update_database $DB_DIR $META --compression-method=$OVERPASS_COMPRESSION) 2>&1 | tee -a /db/changes.log
            rm $DIFF_FILE

            if [ $OSMIUM_STATUS -eq 1 ]; then
                    # try again
                    exit 3
            fi
        )
        UPDATE_STATUS=$?
        if [ $UPDATE_STATUS -eq 3 ] ; then
            sleep 60
        else
            exit 0;
        fi
    done
) 2>&1 | tee -a /db/changes.log