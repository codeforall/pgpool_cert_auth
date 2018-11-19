FROM pgsql-pgpool:10
MAINTAINER m.usama@gmail.com
# Get epas10:latest from https://github.com/richyen/ppas_and_docker/blob/master/epas/10/Dockerfile
ARG MASTER_IP
ARG SLAVE_IP

ENV PGPORT=5432
ENV PGPOOLPORT=9999
ENV PCPPORT=9898

#copy the server certificates
#COPY server.key /server.key
#COPY server.crt /server.crt
#COPY root.crt /root.crt
COPY scripts/wait_for_pg_server.sh /tmp/wait_for_pg_server.sh
RUN sed -i "s/^IP=/IP=$SLAVE_IP/" /tmp/wait_for_pg_server.sh
RUN sed -i "s/^PORT=/PORT=5432/" /tmp/wait_for_pg_server.sh

RUN mkdir /certs
COPY certs/server.key /certs/server.key
COPY certs/server.crt /certs/server.crt 
COPY certs/root.crt /certs/root.crt

# Set up pgpool config files
RUN sed -i "s/^backend_hostname0 = .*/backend_hostname0 = '${MASTER_IP}'/"         ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^#backend_hostname1 = .*/backend_hostname1 = '${SLAVE_IP}'/"         ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^backend_port0 = .*/backend_port0 = ${PGPORT}/"         ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^#backend_port1 = .*/backend_port1 = ${PGPORT}/"        ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^#backend_weight1 = .*/backend_weight1 = 1/"        ${PGPOOLCONF}/pgpool.conf

RUN sed -i "s/^port = .*/port = ${PGPOOLPORT}/"         ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^pid_file_name = .*/pid_file_name = '\/var\/run\/pgpool\/pgpool.pid'/"  ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^listen_addresses = 'localhost'/listen_addresses = '*'/"  ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^ssl = .*/ssl = on/"  ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^#ssl_key = .*/ssl_key = '\/certs\/server.key'/"  ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^#ssl_cert = .*/ssl_cert = '\/certs\/server.crt'/"  ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^#ssl_ca_cert = .*/ssl_ca_cert = '\/certs\/root.crt'/"  ${PGPOOLCONF}/pgpool.conf
RUN sed -i "s/^enable_pool_hba = .*/enable_pool_hba = on/"  ${PGPOOLCONF}/pgpool.conf

RUN echo "sr_check_user = 'postgres'" >> ${PGPOOLCONF}/pgpool.conf
RUN echo "health_check_user = 'postgres'" >> ${PGPOOLCONF}/pgpool.conf
RUN touch ${PGPOOLCONF}/pool_passwd
RUN chown postgres:postgres ${PGPOOLCONF}/pool_passwd

#setup pool_hba.conf

RUN echo "local     all         all                           trust" > ${PGPOOLCONF}/pool_hba.conf
RUN echo "host      all         postgres           0.0.0.0/0  trust" >> ${PGPOOLCONF}/pool_hba.conf
RUN echo "hostssl   all         postgres           0.0.0.0/0  trust" >> ${PGPOOLCONF}/pool_hba.conf
RUN echo "hostnossl all         all                0.0.0.0/0  scram-sha-256" >> ${PGPOOLCONF}/pool_hba.conf
RUN echo "hostssl   all         all                0.0.0.0/0  cert" >> ${PGPOOLCONF}/pool_hba.conf

#create the key file
RUN sudo -u postgres echo "pool_pass_key" > /home/postgres/.pgpoolkey
#RUN chmod 0600 /home/postgres/.pgpoolkey
RUN sudo -u postgres pg_enc -u certuser -m cert_password
RUN sudo -u postgres pg_enc -u scramuser -m scram_password
RUN sudo -u postgres pg_enc -u postgres -m postgres

CMD /tmp/wait_for_pg_server.sh && service ${PGPOOLSERVICE_NAME} start && tail -F ${PGPOOLLOG}

EXPOSE ${PGPOOLPORT}
EXPOSE ${PCPPORT}

