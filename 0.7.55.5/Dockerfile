FROM nginx:1.14

RUN addgroup overpass && adduser --home /db --disabled-password --gecos overpass --ingroup overpass overpass

ADD http://dev.overpass-api.de/releases/osm-3s_v0.7.55.5.tar.gz /app/src.tar.gz

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        autoconf \
        automake \
        bash \
        bzip2 \
        ca-certificates \
        expat \
        fcgiwrap \
        g++ \
        lftp \
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
        zlib1g-dev \
    && mkdir -p /app/src \
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
    && apt-get remove -y \
        autoconf \
        automake \
        libexpat1-dev \
        g++ \
        libtool \
        liblz4-dev \
        m4 \
        make \
        zlib1g-dev \
    && apt-get autoremove -y \
    && mkdir -p /db/diffs /app/etc \
    && cp -r /app/src/rules /app/etc/rules \
    && rm -rf /app/src /app/src.tar.gz \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/

RUN python3 -m venv /app/venv \
    && /app/venv/bin/pip install -r /app/requirements.txt

RUN mkdir /nginx /docker-entrypoint-initdb.d && chown nginx:nginx /nginx && chown -R overpass:overpass /db

COPY etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY etc/nginx-overpass.conf /etc/nginx/nginx.conf

COPY bin/update_overpass.sh bin/update_overpass_loop.sh bin/rules_loop.sh bin/dispatcher_start.sh  /app/bin/

COPY docker-entrypoint.sh /app/

RUN chmod a+x /app/docker-entrypoint.sh /app/bin/update_overpass.sh /app/bin/rules_loop.sh /app/bin/dispatcher_start.sh

ENV OVERPASS_RULES_LOAD 1

EXPOSE 80
# CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
CMD ["/app/docker-entrypoint.sh"]
