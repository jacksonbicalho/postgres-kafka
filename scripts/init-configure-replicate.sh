#!/bin/bash
set -e

if [ $POSTGRES_USER = 'dev-master' ]; then

echo "host    replication     all             10.0.0.3/32             trust" >> /var/lib/postgresql/data/pg_hba.conf
echo "wal_level = logical" >> /var/lib/postgresql/data/postgresql.conf
echo "max_replication_slots = 10" >> /var/lib/postgresql/data/postgresql.conf
echo "max_wal_senders = 10" >> /var/lib/postgresql/data/postgresql.conf


pg_ctl -U $POSTGRES_USER restart -s

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    CREATE ROLE replicate WITH LOGIN PASSWORD 'Azerty' REPLICATION ;
    CREATE PUBLICATION pubusers FOR TABLE users ;
    GRANT SELECT ON users TO replicate ;
    SELECT pg_reload_conf();

EOSQL
fi

if [ $POSTGRES_USER = 'dev-replica' ]; then

    echo "wal_level = logical" >> /var/lib/postgresql/data/postgresql.conf
    echo "max_replication_slots = 10" >> /var/lib/postgresql/data/postgresql.conf
    echo "max_wal_senders = 10" >> /var/lib/postgresql/data/postgresql.conf

    pg_ctl -U dev-replica restart -s

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE SUBSCRIPTION subusers CONNECTION 'host=10.0.0.2 dbname=dev-master user=replicate password=Azerty' PUBLICATION pubusers ;
EOSQL
    pg_recvlogical -U dev-replica -d dev-replica --slot wal2json --create-slot -P wal2json
    ./producer.sh
fi