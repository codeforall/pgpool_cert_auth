FROM pgsql-pgpool:10
MAINTAINER m.usama@gmail.com

ARG ROLE
ARG MASTER_IP

ENV PGPORT=5432
ENV ROLE_=$ROLE
ENV MASTER_IP_=$MASTER_IP


#copy the client certificates
#RUN mkdir ~/.postgresql

COPY ./scripts/setup_pg_server.sh /tmp/setup_pg_server.sh
RUN chmod u+x /tmp/setup_pg_server.sh
RUN sed -i "s/^MASTER_IP=/MASTER_IP=$MASTER_IP/" /tmp/setup_pg_server.sh
RUN sed -i "s/^ROLE=/ROLE=$ROLE/" /tmp/setup_pg_server.sh

#copy the server certificates
COPY certs/server.key ${PGDATA}/server.key
COPY certs/server.crt ${PGDATA}/server.crt 
COPY certs/root.crt ${PGDATA}/root.crt


RUN chmod 0600 ${PGDATA}/server.key && chown postgres:postgres ${PGDATA}/server.key
RUN chmod 0600 ${PGDATA}/server.crt && chown postgres:postgres ${PGDATA}/server.crt
RUN chmod 0600 ${PGDATA}/root.crt && chown postgres:postgres ${PGDATA}/root.crt

RUN echo "wal_level = hot_standby"   >> ${PGDATA}/postgresql.conf
RUN echo "max_wal_senders = 8"       >> ${PGDATA}/postgresql.conf
RUN echo "wal_keep_segments = 100"   >> ${PGDATA}/postgresql.conf
RUN echo "max_replication_slots = 4" >> ${PGDATA}/postgresql.conf
RUN echo "hot_standby = on"          >> ${PGDATA}/postgresql.conf
RUN echo "listen_addresses = '*'"    >> ${PGDATA}/postgresql.conf
RUN echo "ssl = on" >> ${PGDATA}/postgresql.conf
RUN echo "ssl_cert_file = 'server.crt'" >> ${PGDATA}/postgresql.conf
RUN echo "ssl_key_file = 'server.key'" >> ${PGDATA}/postgresql.conf

RUN echo "local  all         all                 trust" >  ${PGDATA}/pg_hba.conf
RUN echo "local  replication all                 trust" >> ${PGDATA}/pg_hba.conf
RUN echo "host   replication all           0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
RUN echo "host   all         postgres      0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
RUN echo "host   all         all      0.0.0.0/0   scram-sha-256" >> ${PGDATA}/pg_hba.conf

RUN echo "export ROLE=${ROLE}"         >> /etc/profile.d/pg_env.sh
CMD /tmp/setup_pg_server.sh &&  service ${PGSERVICE_NAME} start && tail -F ${PGLOG}

EXPOSE ${PGPORT}
