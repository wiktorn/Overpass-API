#!/bin/bash

set -eo pipefail
shopt -s nullglob
OVERPASS_META=${OVERPASS_META:-no}
OVERPASS_MODE=${OVERPASS_MODE:-clone}
OVERPASS_COMPRESSION=${OVERPASS_COMPRESSION:-gz}
OVERPASS_FLUSH_SIZE=${OVERPASS_FLUSH_SIZE:-16}

if [[ "$OVERPASS_META" == "attic" ]] ; then
    META="--keep-attic"
elif [[ "${OVERPASS_META}" == "yes" ]] ; then
    META="--meta"
else
    META=""
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

if [[ ! -f /db/init_done ]] ; then
    echo "No database directory. Initializing"
    if [[ "${USE_OAUTH_COOKIE_CLIENT}" = "yes" ]]; then
      /app/venv/bin/python /app/bin/oauth_cookie_client.py -o /db/cookie.jar -s /secrets/oauth-settings.json --format netscape
      # necessary to add newline at the end as oauth_cookie_client doesn't do that
      echo >> /db/cookie.jar
    else
      echo "# Netscape HTTP Cookie File" > /db/cookie.jar
      echo "${OVERPASS_COOKIE_JAR_CONTENTS}" >> /db/cookie.jar
    fi
    chown overpass /db/cookie.jar

    if [[ "$OVERPASS_MODE" = "clone" ]]; then
        mkdir -p /db/db \
        && /app/bin/download_clone.sh --db-dir=/db/db --source=http://dev.overpass-api.de/api_drolbr/ --meta="${OVERPASS_META}" \
        && cp /db/db/replicate_id /db/replicate_id \
        && cp -r /app/etc/rules /db/db \
        && chown -R overpass:overpass /db \
        && touch /db/init_done \
        && echo "Overpass ready, you can start your container with docker start"
        exit
    fi

    if [[ "$OVERPASS_MODE" = "init" ]]; then
        while `true` ; do
          CURL_STATUS_CODE=$(curl -L -b /db/cookie.jar -o /db/planet.osm.bz2 -w "%{http_code}" "${OVERPASS_PLANET_URL}")
          case "${CURL_STATUS_CODE}" in
            429)
              echo "Server responded with 429 Too many requests. Trying again in 5 minutes..."
              sleep 300
              continue
              ;;
            200)
              (
                if [[ ! -z "${OVERPASS_PLANET_PREPROCESS+x}" ]]; then
                    echo "Running preprocessing command: ${OVERPASS_PLANET_PREPROCESS}"
                    eval "${OVERPASS_PLANET_PREPROCESS}"
                fi \
                && /app/bin/init_osm3s.sh /db/planet.osm.bz2 /db/db /app "${META}" "--version=$(osmium fileinfo -e -g data.timestamp.last /db/planet.osm.bz2) --compression-method=${OVERPASS_COMPRESSION} --map-compression-method=${OVERPASS_COMPRESSION} --flush-size=${OVERPASS_FLUSH_SIZE}" \
                && echo "Database created. Now updating it." \
                && cp -r /app/etc/rules /db/db \
                && chown -R overpass:overpass /db \
                && echo "Updating" \
                && /app/bin/update_overpass.sh "-O /db/planet.osm.bz2" \
                && touch /db/init_done \
                && rm /db/planet.osm.bz2 \
                && chown -R overpass:overpass /db \
                && echo "Overpass ready, you can start your container with docker start" \
                && exit
              ) || (
                echo "Failed to process planet file"
                exit
              )
              ;;
            403)
              echo "Access denied when downloading planet file. Check your OVERPASS_PLANET_URL and OVERPASS_COOKIE_JAR_CONTENTS or USE_OAUTH_COOKIE_CLIENT"
              cat /db/cookie.jar
              exit
              ;;
            *)
              cat /db/planet.osm.bz2
              echo "Failed to download planet file. HTTP status code: ${CURL_STATUS_CODE}"
              exit
              ;;
          esac
          exit
        done
    fi
fi

echo "Starting supervisord process"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
