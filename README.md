# pgpool_cert_auth
This repository showcase the example of using cert (certificate) based authentication with
Pgpool-II.

# Overview
The example creates four containers "pgmaster", "pgslave", "pgpoolnode" and "clientnode".
"pgmaster" and "pgslave" hosts the PostgreSQL instance master and standby respectively, While "pgpoolnode" runs the Pgpool-II and "clientnode" is used for testing the client connections.

All these above mentioned images are created using "pgsql-pgpool" docker image (also created by this example),
which is just a centos:6.6 docker image with PostgreSQL and Pgpool-II installed.

# Authentication setup
The system is configured to use the "cert" (certificate) based authentication for SSL connections to Pgpool-II while Pgpool-II uses the "scram-sha-256" auth for backend PostgreSQL connections.
Non SSL connections to Pgpool-II requires "scram-sha-256" auth.

# User configurations in PostgreSQL
In this example we create three PostgreSQL uses, "postgres", "certuser" and "scramuser", and allows the 
trust authentication to "postgres" user, while "certuser" and "scramuser" requires scram-sha-256 authentication.

pg_hba.conf
```
local  all         all                      trust
local  replication all                      trust
host   replication all           0.0.0.0/0  trust
host   all         postgres      0.0.0.0/0  trust
host   all         all           0.0.0.0/0  scram-sha-256
```

# User configurations in Pgpool-II
Pgpool-II only allows "cert" authentication for SSL connections and "scram-sha-256" for non ssl connections with the exception of postgres user, which enjoys the trust auth for this test.

pool_hba.conf
```
local     all         all                           trust
host      all         postgres           0.0.0.0/0  trust
hostssl   all         postgres           0.0.0.0/0  trust
hostnossl all         all                0.0.0.0/0  scram-sha-256
hostssl   all         all                0.0.0.0/0  cert
```
# How to build and run

To run the exmaple do the following:
```
docker-compose build
docker-compose up
```
# Testing

To test the cert auth connect with "certuser" 
```
$ docker exec -it clientnode sudo -u postgres psql "sslmode=require port=9999 host=172.22.0.52 dbname=postgres user=certuser" -c "show pool_nodes"
 node_id |  hostname   | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay | last_status_change  
---------+-------------+------+--------+-----------+---------+------------+-------------------+-------------------+---------------------
 0       | 172.22.0.50 | 5432 | up     | 0.500000  | primary | 0          | false             | 0                 | 2018-11-15 16:06:33
 1       | 172.22.0.51 | 5432 | up     | 0.500000  | standby | 0          | true              | 0                 | 2018-11-15 16:06:33
(2 rows)
```

Now -ve scenario, Try connecting with "scramuser"

```
$ docker exec -it clientnode sudo -u postgres psql "sslmode=require port=9999 host=172.22.0.52 dbname=postgres user=scramuser" -c "show pool_nodes"
psql: ERROR:  CERT authentication failed
DETAIL:  no valid certificate presented
```
