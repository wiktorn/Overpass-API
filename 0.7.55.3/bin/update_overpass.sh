#!/bin/bash

# TODO: split to two files - one with while loop for unattended use
# one for updating to current state - second called by first

DIFF_FILE=/db/diffs/changes.osm

(
    set -e
    if [[ "${OVERPASS_META}" == "attic" ]] ; then
        META="--keep-attic"
    elif [[ "${OVERPASS_META}" == "yes" ]] ; then
        META="--meta"
    else
        META=""
    fi

    if [[ ! -d /db/diffs ]] ; then
        mkdir /db/diffs
    fi

    if /app/bin/dispatcher --show-dir | grep -q File_Error ; then
        DB_DIR="--db-dir=/db/db"
    else
        DB_DIR=""
    fi

    while `true` ; do
        if [[ ! -e  /db/diffs/changes.osm ]] ; then
            set +e
            /app/venv/bin/pyosmium-get-changes -vvv $1 --server "${OVERPASS_DIFF_URL}" -o "${DIFF_FILE}" -f /db/replicate_id
            OSMIUM_STATUS=$?
            set -e
            #if [[ "${OSMIUM_STATUS}" -eq 2 ]]; then
            #    echo "Failure downloading updates"
            #    sleep 60
            #    continue
            #fi
        else
            echo "/db/diffs/changes.osm exists. Trying to apply again."
        fi
        echo /app/bin/update_database "${DB_DIR}" "${META}" --compression-method="${OVERPASS_COMPRESSION}" --map-compression-method="${OVERPASS_COMPRESSION}"
        cat "${DIFF_FILE}" | /app/bin/update_database "${DB_DIR}" "${META}" --compression-method="${OVERPASS_COMPRESSION}" --map-compression-method="${OVERPASS_COMPRESSION}"
        rm "${DIFF_FILE}"

        #if [[ "${OSMIUM_STATUS}" -eq 1 ]]; then
        #    echo "There are still some updates remaining"
        #    continue
        #else
        #    echo "Update finished with status code: ${OSMIUM_STATUS}"
        #    break
        #fi
        # for now, until pyosmium-get-changes status code gets cleared
        break
    done
) 2>&1 | tee -a /db/changes.log