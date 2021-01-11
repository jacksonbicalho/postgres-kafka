FROM postgres AS Master

COPY scripts/1.sql /docker-entrypoint-initdb.d/
COPY scripts/init-configure-replicate.sh /docker-entrypoint-initdb.d/

FROM Master AS Replica

ENV DEBIAN_FRONTEND noninteractive
ENV PROTOC_VERSION=1.3
ENV WAL2JSON_COMMIT_ID=8600d480de304ffe4c6a313b6fba1e411ab2e706
ARG BROKER=localhost:9092
ARG USER_REPLICA
ARG DB_REPLICA
ARG TOPIC

RUN apt-get update \
    && apt-get install -f -y --no-install-recommends \
        software-properties-common \
        build-essential \
        pkg-config \
        git \
        librdkafka-dev \
        libyajl-dev \
        kafkacat \
        postgresql-server-dev-$PG_MAJOR \
    && add-apt-repository "deb http://ftp.debian.org/debian testing main contrib" \
    && apt-get update && apt-get install -f -y --no-install-recommends \
        libprotobuf-c-dev=$PROTOC_VERSION.* \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/eulerto/wal2json -b master --single-branch \
    && cd /wal2json \
    && git checkout $WAL2JSON_COMMIT_ID \
    && make && make install \
    && /usr/bin/install -c -m 755  wal2json.so "/usr/lib/postgresql/$PG_MAJOR/lib/" \
    && cd / \
    && rm -rf wal2json

WORKDIR /app
COPY scripts/producer.sh /app
RUN chmod +x /app/producer.sh

RUN sed -i.bak "s|BROKER|${BROKER}|g" /app/producer.sh
RUN sed -i.bak "s|USER_REPLICA|${USER_REPLICA}|g" /app/producer.sh
RUN sed -i.bak "s|DB_REPLICA|${DB_REPLICA}|g" /app/producer.sh
RUN sed -i.bak "s|TOPIC|${TOPIC}|g" /app/producer.sh

EXPOSE 5432

