FROM ubuntu:latest

# Maintainer
MAINTAINER Alexander Eisele <alexander@eiselecloud.de>

# install homerserver template
COPY adds/start.sh /start.sh

# add supervisor configs
COPY adds/supervisord-matrix.conf /conf/
COPY adds/supervisord-turnserver.conf /conf/
COPY adds/supervisord.conf /

# startup configuration
ENTRYPOINT ["/start.sh"]
CMD ["autostart"]
EXPOSE 8448
VOLUME ["/data"]

# Git branch to build from
ARG BV_SYN=master
ARG BV_TUR=master
ARG TAG_SYN=v0.34.1+1

# user configuration
ENV MATRIX_UID=991 MATRIX_GID=991

# use --build-arg REBUILD=$(date) to invalidate the cache and upgrade all
# packages
ARG REBUILD=1
RUN set -ex \
    && mkdir /uploads \
    && export DEBIAN_FRONTEND=noninteractive \
    && mkdir -p /var/cache/apt/archives \
    && touch /var/cache/apt/archives/lock \
    && apt-get clean \
    && apt-get update -y -q --fix-missing\
    && apt-get upgrade -y \
    && buildDeps=' \
        file \
        gcc \
        git \
        libevent-dev \
        libffi-dev \
        libgnutls28-dev \
        libjpeg-turbo8-dev \
        libldap2-dev \
        libsasl2-dev \
        libsqlite3-dev \
        libssl-dev \
        libtool \
        libxml2-dev \
        libxslt1-dev \
        make \
        pypy-dev \
        zlib1g-dev \
        libpq-dev \
        curl \
        ca-certificates \
    ' \
    && apt-get install -y --no-install-recommends \
        $buildDeps \
        bash \
        coreutils \
        coturn \
        libevent-2.1-6 \
        libffi6 \
        libjpeg-turbo8 \
        libldap-2.4-2 \
        libssl1.1 \
        libtool \
        libxml2 \
        libxslt1.1 \
        pwgen \
        pypy \
        sqlite \
        zlib1g \
    ; \
    curl https://bootstrap.pypa.io/get-pip.py | pypy - ;\
    pip install --upgrade wheel ;\
    pip install --upgrade python-ldap ;\
    pip install --upgrade pyopenssl ;\
    pip install --upgrade enum34 ;\
    pip install --upgrade ipaddress ;\
    pip install --upgrade supervisor ;\
    pip install --upgrade psycopg2cffi ;\
    echo "from psycopg2cffi import compat; compat.register()" >> /usr/local/lib/pypy2.7/dist-packages/psycopg2.py \
    ; \
    git clone --branch $TAG_SYN --depth 1 https://github.com/matrix-org/synapse.git \
    && cd /synapse ;\
    git checkout tags/$TAG_SYN \
    && pip install --upgrade --process-dependency-links . \
    && pip uninstall psycopg2 -y \
    && GIT_SYN=$(git ls-remote https://github.com/matrix-org/synapse $BV_SYN | cut -f 1) \
    && echo "synapse: $BV_SYN ($GIT_SYN)" >> /synapse.version \
    && cd / \
    && rm -rf /synapse \
    ; \
    apt-get autoremove -y $buildDeps ;\
    apt-get autoremove -y ;\
    rm -rf /var/lib/apt/* /var/cache/apt/*
