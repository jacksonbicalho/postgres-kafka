Replicação PostgreSQL com um produtor de mensagens para o Kafka rodando no servidor de replicação
===

## Replica uma tabela do PostgreSQL em servidores diferentes
---

#### Constroi duas images, postgres-replica e postgres-master usando como base [POSTGREES](https://github.com/docker-library/postgres/blob/03e769531fff4c97cb755e4a608b24935ceeee27/13/Dockerfile)
<br />

Copia `1.sql` e `init-configure-replicate.sh` de `./scripts` para `/docker-entrypoint-initdb.d/`
<br />

#### `init-configure-replicate.sh` condiciona suas ações ao valor definido em `POSTGRES_USER` [:warning:](isso deve ser mudado)
<br />

### Master
---

#### `init-configure-replicate.sh` registra em /var/lib/postgresql/data/pg_hba.conf uma permissão para o host 10.0.0.3 do tipo relicaçação para qualquer usuário
* Recarrega a configuração
* Cria uma regra replicate com o password `'Azerty'`
* Cria uma publicação chamada pubusers para a tabela users
* Garante a regra replicate o acesso a leirura à tabela users
* Recarrega a configuração

```sql
    ALTER SYSTEM SET ;
    SELECT pg_reload_conf();
    CREATE ROLE replicate WITH LOGIN PASSWORD 'Azerty' REPLICATION ;
    CREATE PUBLICATION pubusers FOR TABLE users ;
    GRANT SELECT ON users TO replicate ;
    SELECT pg_reload_conf();

```


### Replica

* Usando a imagem construída anteriormente configura

* * [wal_level](https://www.postgresql.org/docs/13/runtime-config-wal.html) para logical

* * [max_replication_slots](https://www.postgresql.org/docs/13/runtime-config-replication.html) para 10

* * [max_wal_senders](https://www.postgresql.org/docs/13/runtime-config-replication.html) para 10

* * Reinicia a configuração
* * Faz uma inscrição em `0.0.0.2` usando os mesmos dados definidos no servidor mater


```bash
    echo "wal_level = logical" >> /var/lib/postgresql/data/postgresql.conf
    echo "max_replication_slots = 10" >> /var/lib/postgresql/data/postgresql.conf
    echo "max_wal_senders = 10" >> /var/lib/postgresql/data/postgresql.conf


psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT pg_reload_conf();
    CREATE SUBSCRIPTION subusers CONNECTION 'host=10.0.0.2 dbname=dev-master user=replicate password=Azerty' PUBLICATION pubusers ;
EOSQL

    pg_ctl -U dev-replica restart -s
    pg_recvlogical -U dev-replica -d dev-replica --slot wal2json --create-slot -P wal2json
    ./producer.sh
```


### Instala no servidor usado como réplica ( # tendo ainda algumas coisas a serem definidas ) o plugin wal2json.

### O servidor [jacksonbicalho/kafka](https://github.com/jacksonbicalho/kafka) deve estar iniciado para este exemplo, `NÃO HÁ AINDA VERIFICAÇÃO` em ./producer.sh se o servidor está ou não disponível.
<br />


## Configuração
---

```bash
$ cp EXAMPLE.env .env


$ cat EXAMPLE.env
# Data Storage
DATA_STORAGE =./data

# Data base master
POSTGRES_USER_MASTER=dev-master
POSTGRES_PASSWORD_MASTER=dev-master
POSTGRES_DB_MASTER=dev-master

# Data base replica
POSTGRES_USER_REPLICA=dev-replica
POSTGRES_PASSWORD_REPLICA=dev-replica
POSTGRES_DB_REPLICA=dev-replica


# brocker (optional)
#   FORMAT:
#     BROKER=host_name|ip:port
#   EXAMPLES:
#       BROKER=192.168.0.1:9092
#       BROKER=mydomain.com.br:9092
# use host and port value defined in kafka advertised.listeners
# https://kafka.apache.org/documentation/#brokerconfigs_advertised.listeners
BROKER=192.168.0.1:9092
KAFKA_TOPIC=topico1
```

## Uso
---
  > O kafka deve estar rodando !!
```bash
$ docker-composer -up
```
Dependendo das permissões do diretório definido em DATA_STORAGE (caso ele exista), pode ser necessário alterar suas permissões.

## Referências
---

* Replicação lógica
   - https://www.postgresql.org/docs/13/logical-replication.html


* Plugin
  - https://github.com/eulerto/wal2json
  - https://www.postgresql.org/docs/13/logicaldecoding-output-plugin.html


* Produtor
  - https://github.com/edenhill/kafkacat
  -https://packages.debian.org/sid/libprotobuf-c-dev
