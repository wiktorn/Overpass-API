
# How to use this image

By default, this image will clone an existing Overpass server for the whole planet, and make it available at `http://localhost/api/interpreter`.

The following enviroment variables can be used to customize the setup:

* `OVERPASS_MODE` - takes the value of either `init` or `clone`. Defaults to `clone`.
* `OVERPASS_META` - (`init` mode only) `yes`, `no` or `attic` - passed to Overpass as `--meta` or `--keep-attic`.
* `OVERPASS_PLANET_URL` - (`init` mode only) url to a "planet" file (e.g. https://planet.openstreetmap.org/planet/planet-latest.osm.bz2)
* `OVERPASS_CLONE_SOURCE` - (`clone` mode only) the url to clone a copy of Overpass from. Defaults to http://dev.overpass-api.de/api_drolbr/, which uses minute diffs.
* `OVERPASS_DIFF_URL` - url to a diff directory for updating the instance (e.g. https://planet.openstreetmap.org/replication/minute/).
* `OVERPASS_COMPRESSION` - (`init` mode only) takes values of `no`, `gz` or `lz4`. Specifies compression mode of the Overpass database. Defaults to `gz`.
* `OVERPASS_RULES_LOAD` - integer, desired load from area generation. Controls the ratio of sleep to work. A value of 1 will make the system sleep 99x times longer than it works, a value of 50 will result in sleep and work in equal measure, and a value of 100 will only sleep 3 seconds between each execution. Defaults to 1.
* `OVERPASS_UPDATE_SLEEP` - integer, the delay between updates (seconds).
* `OVERPASS_COOKIE_JAR_CONTENTS` - cookie-jar compatible content to be used when fetching planet.osm files and updates.
* `OVERPASS_PLANET_PREPROCESS` - commands to be run before passing the planet.osm file to `update_database`, e.g. conversion from pbf to osm.bz2 using osmium.
* `USE_OAUTH_COOKIE_CLIENT` - set to `yes` if you want to use oauth_cookie_client to update cookies before each update. Settings are read from /secrets/oauth-settings.json. Read the documentation [here](https://github.com/geofabrik/sendfile_osm_oauth_protector/blob/master/doc/client.md).
* `OVERPASS_FASTCGI_PROCESSES` - number of fcgiwarp processes. Defaults to 4. Use higher values if you notice performance problems.
* `OVERPASS_RATE_LIMIT` - set the maximum allowed number of concurrent accesses from a single IP address.
* `OVERPASS_TIME` - set the maximum amount of time units (available time).
* `OVERPASS_SPACE` - set the maximum amount of RAM (available space) in bytes.
* `OVERPASS_MAX_TIMEOUT` - set the maximum timeout for queries (default: 1000s). Translates to send/recv timeout for fastcgi_wrap.
* `OVERPASS_USE_AREAS` - if `false` initial area generation and the area updater process will be disabled. Default `true`.
* `OVERPASS_HEALTHCHECK` - shell commands to execute to verify that image is healthy. `exit 1` in case of failures, `exit 0` when container is healthy. Default healthcheck queries overpass and verifies that there is reponse returned
* `OVERPASS_STOP_AFTER_INIT` - if `false` the container will keep runing after init is complete. Otherwise container will be stopped after initialization process is complete. Default `true`

### Modes

Image works in two modes `init` or `clone`. This affects how the instance gets initialized:

* `init` - OSM data is downloaded from `OVERPASS_PLANET_URL`, which can be a full planet or partial planet dump.
This file will then be indexed by Overpass and later updated using `OVERPASS_DIFF_URL`.

* `clone` - data is copied from an existing server, given by `OVERPASS_CLONE_SOURCE`, and then updated using `OVERPASS_DIFF_URL`.
This mode is faster to set up, as the OSM planet file is already indexed.
The default clone source provides an Overpass instance using minute diffs covering the whole world (hourly or daily diffs will not work with this image).

### Running

To monitor the progress of file downloads, run with the stdin (`-i`) and TTY  (`-t`) flags:
`docker run -i -t wiktorn/overpass-api`

After initialization is finished, the Docker container will stop. Once you start it again (with `docker start` command) it will start downloading diffs, applying them to database, and serving API requests.

The container exposes port 80. Map it to your host port using `-p`:
`docker run -p 80:80 wiktorn/overpass-api`

The Overpass API will then be available at `http://localhost:80/api/interpreter`.

Container includes binaries of pyosmium (in `/app/venv/bin/`) and osmium-tool (in `/usr/bin`)

All data resides within the `/db` directory in the container.

For convenience, a [`docker-compose.yml` template](./docker-compose.yml) is included.

# Examples
## Overpass instance covering part of the world
In this example the Overpass instance will be initialized with a planet file for Monaco downloaded from Geofabrik.
Data will be stored in folder`/big/docker/overpass_db/` on the host machine and will not contain metadata as this example uses public Geofabrik extracts that do not contain metadata (such as changeset and user).
Overpass will be available on port 12345 on the host machine.
```
docker run \
  -e OVERPASS_META=yes \
  -e OVERPASS_MODE=init \
  -e OVERPASS_PLANET_URL=http://download.geofabrik.de/europe/monaco-latest.osm.bz2 \
  -e OVERPASS_DIFF_URL=http://download.openstreetmap.fr/replication/europe/monaco/minute/ \
  -e OVERPASS_RULES_LOAD=10 \
  -v /big/docker/overpass_db/:/db \
  -p 12345:80 \
  -i -t \
  --name overpass_monaco wiktorn/overpass-api
```

## Overpass clone covering whole world
In this example Overpass instance will be initialized with data from main Overpass instance and updated with master planet diffs.
Data will be stored in `/big/docker/overpass_clone_db/`  on the host machine and the API will be available on port 12346 on the host machine.
```
docker run \
  -e OVERPASS_META=yes \
  -e OVERPASS_MODE=clone \
  -e OVERPASS_DIFF_URL=https://planet.openstreetmap.org/replication/minute/ \
  -v /big/docker/overpass_clone_db/:/db \
  -p 12346:80 \
  -i -t \
  --name overpass_world \
  wiktorn/overpass-api
```

## Overpass instance covering part of the world using cookie
In this example Overpass instance will be initialized with planet file for Monaco downloaded from internal Geofabrik server.
Data will be stored in `/big/docker/overpass_db/` on the host machine and the API will be available on port 12347 on the host machine.

Prepare file with your credentials `/home/osm/oauth-settings.json`:
```json
{
  "user": "your-username",
  "password": "your-secure-password",
  "osm_host": "https://www.openstreetmap.org",
  "consumer_url": "https://osm-internal.download.geofabrik.de/get_cookie"
}
```

Because Geofabrik provides only PBF extracts with metadata, `osmium` is used in `OVERPASS_PLANET_PREPROCESS` to convert the `pbf` file to `osm.bz2` that's used by Overpass.

```
docker run \
    -e OVERPASS_META=yes \
    -e OVERPASS_MODE=init \
    -e OVERPASS_PLANET_URL=https://osm-internal.download.geofabrik.de/europe/monaco-latest-internal.osm.pbf \
    -e OVERPASS_DIFF_URL=https://osm-internal.download.geofabrik.de/europe/monaco-updates/ \
    -e OVERPASS_RULES_LOAD=10 \
    -e OVERPASS_COMPRESSION=gz \
    -e OVERPASS_UPDATE_SLEEP=3600 \
    -e OVERPASS_PLANET_PREPROCESS='mv /db/planet.osm.bz2 /db/planet.osm.pbf && osmium cat -o /db/planet.osm.bz2 /db/planet.osm.pbf && rm /db/planet.osm.pbf' \
    -e USE_OAUTH_COOKIE_CLIENT=yes \
    --mount type=bind,source=/home/osm/oauth-settings.json,target=/secrets/oauth-settings.json \
    -v /big/docker/overpass_db/:/db \
    -p 12347:80 \
    -i -t \
    --name overpass_monaco wiktorn/overpass-api
```

## Healthcheck checking that instance is up-to-date
Using following environment variable:
```
-e OVERPASS_HEALTHCHECK='
  OVERPASS_RESPONSE=$(curl -s "http://localhost/api/interpreter?data=\[out:json\];node(1);out;" | jq -r .osm3s.timestamp_osm_base)
  OVERPASS_DATE=$(date -d "$OVERPASS_RESPONSE" +%s)
  TWO_DAYS_AGO=$(($(date +%s) - 2*86400)) ;
  if [ ${OVERPASS_DATE} -lt ${TWO_DAYS_AGO} ] ; then
    echo "Overpass out of date. Overpass date: ${OVERPASS_RESPONSE}"
    exit 1;
  fi
  echo "Overpass date: ${OVERPASS_RESPONSE}"
'
```
healthcheck will verify the date of last update of Overpass instance and if data in instance are earlier than two days ago, healthcheck will fail.


# How to use Overpass after deploying using above examples
The Overpass API will be exposed on the port exposed by `docker run` - for example `http://localhost:12346/api/interpreter`.

You may then use this directly as an Overpass API url, or use it within [Overpass Turbo](http://overpass-turbo.eu/).

Try a direct query with `http://localhost:12346/api/interpreter?data=node(3470507586);out geom;`, which should return a pub in Dublin.

To use the API in Overpass Turbo, go to settings and set Server to`http://localhost:12346/api/`. Now you will use your local Overpass instance for your queries.
