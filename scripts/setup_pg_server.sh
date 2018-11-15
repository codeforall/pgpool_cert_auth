#!/bin/bash -x
MASTER_IP=
ROLE=
echo setting up server in $ROLE role.

if test -z $ROLE ; then 
    echo "server role not provided"
fi

if [ $ROLE = "standby" ]; then
    # wait for master server to get online
    until psql -h ${MASTER_IP} -U "postgres" -c '\q'; do
          >&2 echo "Postgres is unavailable - sleeping"
            sleep 1
    done
    echo "mastar Postgres is up - executing basebackup command"
    #delete the old data forlder first
    rm -rf ${PGDATA}
    sudo -u postgres pg_basebackup -RP -p 5432 -h ${MASTER_IP} -D ${PGDATA}
fi
