#!/bin/bash

# TODO: split to two files - one with while loop for unattended use
# one for updating to current state - second called by first

DIFF_FILE=/db/diffs/changes.osm

(
    set -e
    UPDATE_ARGS=("--compression-method=${OVERPASS_COMPRESSION}" "--map-compression-method=${OVERPASS_COMPRESSION}" "--flush-size=${OVERPASS_FLUSH_SIZE}")
    if [[ "${OVERPASS_META}" == "attic" ]] ; then
        UPDATE_ARGS+=("--keep-attic")
    elif [[ "${OVERPASS_META}" == "yes" ]] ; then
        UPDATE_ARGS+=("--meta")
    fi

    if [[ ! -d /db/diffs ]] ; then
        mkdir /db/diffs
    fi

    if /app/bin/dispatcher --show-dir | grep -q File_Error ; then
        UPDATE_ARGS+=("--db-dir=/db/db")
    fi

    while `true` ; do
        if [[ ! -e  /db/diffs/changes.osm ]] ; then
            # if /db/replicate_id exists, do not pass $1 arg (which could contain -O arg pointing to planet file
            if [[ -s /db/replicate_id ]] ; then
                set +e
                /app/venv/bin/pyosmium-get-changes -vvv --server "${OVERPASS_DIFF_URL}" -o "${DIFF_FILE}" -f /db/replicate_id
                OSMIUM_STATUS=$?
                set -e
            else
                set +e
                /app/venv/bin/pyosmium-get-changes -vvv $1 --server "${OVERPASS_DIFF_URL}" -o "${DIFF_FILE}" -f /db/replicate_id
                OSMIUM_STATUS=$?
                set -e
            fi
        else
            echo "/db/diffs/changes.osm exists. Trying to apply again."
        fi

        echo /app/bin/update_database "${UPDATE_ARGS[@]}"
        cat "${DIFF_FILE}" | /app/bin/update_database "${UPDATE_ARGS[@]}"
        rm "${DIFF_FILE}"

        if [[ "${OSMIUM_STATUS}" -eq 3 ]]; then
            echo "Update finished with status code: ${OSMIUM_STATUS}"
            break
        else
            echo "There are still some updates remaining"
            continue
        fi
        # for now, until pyosmium-get-changes status code gets cleared
        break
    done
) 2>&1 | tee -a /db/changes.log
