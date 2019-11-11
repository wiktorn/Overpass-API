FROM nginx:1.14 AS builder

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        autoconf \
        automake \
        bash \
        bzip2 \
        ca-certificates \
        curl \
        expat \
        fcgiwrap \
        g++ \
        libexpat1-dev \
        liblz4-1 \
        liblz4-dev \
        libtool \
        m4 \
        make \
        osmium-tool \
        python3 \
        python3-venv \
        supervisor \
        wget \
        zlib1g \
        zlib1g-dev

ADD http://dev.overpass-api.de/releases/osm-3s_v0.7.55.tar.gz /app/src.tar.gz

RUN  mkdir -p /app/src \
    && cd /app/src \
    && tar -x -z --strip-components 1 -f ../src.tar.gz \
    && autoscan \
    && aclocal \
    && autoheader \
    && libtoolize \
    && automake --add-missing  \
    && autoconf \
    && CXXFLAGS='-O2' CFLAGS='-O2' ./configure --prefix=/app --enable-lz4 \
    && make -j $(grep -c ^processor /proc/cpuinfo) dist install clean \
    && mkdir -p /db/diffs /app/etc \
    && cp -r /app/src/rules /app/etc/rules \
    && rm -rf /app/src /app/src.tar.gz

FROM nginx:1.14

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        bash \
        bzip2 \
        ca-certificates \
        curl \
        expat \
        fcgiwrap \
        liblz4-1 \
        osmium-tool \
        python3 \
        python3-venv \
        supervisor \
        wget \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app /app

ADD https://raw.githubusercontent.com/geofabrik/sendfile_osm_oauth_protector/7a6e540734d36dce94aa6be5194c08af1eee2d3f/oauth_cookie_client.py \
    /app/bin/

RUN addgroup overpass && adduser --home /db --disabled-password --gecos overpass --ingroup overpass overpass

COPY requirements.txt /app/

RUN python3 -m venv /app/venv \
    && /app/venv/bin/pip install -r /app/requirements.txt

RUN mkdir /nginx /docker-entrypoint-initdb.d && chown nginx:nginx /nginx && chown -R overpass:overpass /db

COPY etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY etc/nginx-overpass.conf /etc/nginx/nginx.conf

COPY bin/update_overpass.sh bin/update_overpass_loop.sh bin/rules_loop.sh bin/dispatcher_start.sh  /app/bin/

COPY docker-entrypoint.sh /app/

RUN chmod a+rx /app/docker-entrypoint.sh /app/bin/update_overpass.sh /app/bin/rules_loop.sh /app/bin/dispatcher_start.sh \
    /app/bin/oauth_cookie_client.py

ENV OVERPASS_RULES_LOAD 1

EXPOSE 80
# CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
CMD ["/app/docker-entrypoint.sh"]
