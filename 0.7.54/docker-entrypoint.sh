#!/bin/bash

set -eo pipefail
shopt -s nullglob
OVERPASS_META=${OVERPASS_META:-no}
OVERPASS_MODE=${OVERPASS_MODE:-clone}
OVERPASS_COMPRESSION=${OVERPASS_COMPRESSION:-gz}

if [[ "$OVERPASS_META" == "attic" ]] ; then
    META="--keep-attic"
else
    META="--meta"
fi


if [ ! -d /db/db ] ; then
    if [ "$OVERPASS_MODE" = "clone" ]; then
        mkdir -p /db/db \
        && /app/bin/download_clone.sh --db-dir=/db/db --source=http://dev.overpass-api.de/api_drolbr/ $META \
        && cp -r /app/etc/rules /db/db \
        && chown -R overpass:overpass /db \
        && echo "Overpass ready, you can start your container with docker start"
        exit
    fi

    if [ "$OVERPASS_MODE" = "init" ]; then
        lftp -c "get -c \"$OVERPASS_PLANET_URL\" -o /db/planet.osm.bz2; exit" \
        && /app/bin/init_osm3s.sh /db/planet.osm.bz2 /db/db /app "--meta=$OVERPASS_META" "--compression-method=$OVERPASS_COMPRESSION --map-compression-method=$OVERPASS_COMPRESSION"\
        && echo "Database created. Now updating it." && (
            ! /app/venv/bin/pyosmium-get-changes -O /db/planet.osm.bz2 --server $OVERPASS_DIFF_URL -o /db/changes.osm -f /db/replicate_id
            OSMIUM_STATUS=$?
            if [ $OSMIUM_STATUS -eq 1 ]; then
                echo "There are still some updates remainging"
            fi
            if [ $OSMIUM_STATUS -eq 2 ]; then
                echo "Failure downloading updates"
                exit 0
            fi
            (cat /db/changes.osm | /app/bin/update_database --db-dir=/db/db $META --compression-method=$OVERPASS_COMPRESSION) 2>&1 | tee -a /db/changes.log
        ) \
        && rm /db/planet.osm.bz2 /db/changes.osm \
        && cp -r /app/etc/rules /db/db \
        && chown -R overpass:overpass /db \
        && echo "Overpass ready, you can start your container with docker start"
        exit
    fi
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
