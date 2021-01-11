#!/bin/bash
pg_recvlogical -U USER_REPLICA -d DB_REPLICA \
 --slot wal2json --start -o pretty-print=1 -o \
 add-msg-prefixes=wal2json -f - | kafkacat -T -P -b BROKER -t TOPIC