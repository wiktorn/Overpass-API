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

for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
        *.sh)
            if [[ -x "$f" ]]; then
                echo "$0: running $f"
                "$f"
            else
                echo "$0: sourcing $f"
                . "$f"
            fi
            ;;
        *)        echo "$0: ignoring $f" ;;
    esac
    echo
done


if [[ ! -d /db/db ]] ; then
    if [[ "$OVERPASS_MODE" = "clone" ]]; then
        mkdir -p /db/db \
        && /app/bin/download_clone.sh --db-dir=/db/db --source=http://dev.overpass-api.de/api_drolbr/ $META \
        && cp -r /app/etc/rules /db/db \
        && chown -R overpass:overpass /db \
        && echo "Overpass ready, you can start your container with docker start"
        exit
    fi

    if [[ "$OVERPASS_MODE" = "init" ]]; then
        lftp -c "get -c \"$OVERPASS_PLANET_URL\" -o /db/planet.osm.bz2; exit" \
        && /app/bin/init_osm3s.sh /db/planet.osm.bz2 /db/db /app "--meta=$OVERPASS_META" "--compression-method=$OVERPASS_COMPRESSION --map-compression-method=$OVERPASS_COMPRESSION" \
        && echo "Database created. Now updating it." \
        && cp -r /app/etc/rules /db/db \
        && chown -R overpass:overpass /db \
        && echo "Updating" \
        && /app/bin/update_overpass.sh "-O /db/planet.osm.bz2" \
        && rm /db/planet.osm.bz2 \
        && chown -R overpass:overpass /db \
        && echo "Overpass ready, you can start your container with docker start"
        exit
    fi
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
