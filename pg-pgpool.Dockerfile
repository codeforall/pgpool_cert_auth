FROM centos:6.6
MAINTAINER m.usama@gmail.com

ARG CERTUSERNAME

ENV PGMAJOR=10
ENV PGPOOLVER=4.0.1
ENV PGSERVICE_NAME=postgresql-${PGMAJOR}
ENV PGPOOLSERVICE_NAME=pgpool-II-${PGMAJOR}
ENV PATH=/usr/pgsql-${PGMAJOR}/bin:${PATH}
ENV PGDATA=/var/lib/pgsql/${PGMAJOR}/data
ENV PGPOOLCONF=/etc/pgpool-II-${PGMAJOR}
ENV PGLOG=/var/lib/pgsql/${PGMAJOR}/pgstartup.log
ENV PGPOOLLOG=/var/log/pgpool-II-${PGMAJOR}.log
ENV CERTDIR=/certificates

RUN adduser --home-dir /home/postgres --create-home postgres

RUN rpm -Uvh https://yum.postgresql.org/${PGMAJOR}/redhat/rhel-6-x86_64/pgdg-redhat10-10-2.noarch.rpm
RUN yum install -y yum-plugin-ovl
RUN yum -y install sudo
RUN yum -y install postgresql${PGMAJOR}-server postgresql${PGMAJOR}
RUN yum -y install pgpool-II-${PGMAJOR}-${PGPOOLVER}
RUN yum -y install vim
RUN echo 'root:root'|chpasswd

# setting postgres user for login
RUN echo 'postgres   ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
RUN echo 'postgres:postgres'|chpasswd

#copy scripts for generating certificates
#RUN mkdir ${CERTDIR}
#COPY ./scripts/generate_client_ssl_crt.sh ${CERTDIR}/generate_client_ssl_crt.sh
#COPY ./scripts/generate_server_ssl_crt.sh ${CERTDIR}/generate_server_ssl_crt.sh

#create certificates
#RUN if [ "x$CERTUSERNAME" = "x" ] ; then cd ${CERTDIR} && ./generate_server_ssl_crt.sh certuser; else cd ${CERTDIR} && ./generate_server_ssl_crt.sh ${CERTUSERNAME}; fi
#RUN if [ "x$CERTUSERNAME" = "x" ] ; then cd ${CERTDIR} && ./generate_client_ssl_crt.sh certuser; else cd ${CERTDIR} && ./generate_client_ssl_crt.sh ${CERTUSERNAME}; fi

#initialize database
RUN service ${PGSERVICE_NAME} initdb

#set the pgpool config files
RUN cp ${PGPOOLCONF}/pgpool.conf.sample-stream ${PGPOOLCONF}/pgpool.conf
RUN cp ${PGPOOLCONF}/pcp.conf.sample ${PGPOOLCONF}/pcp.conf
RUN cp ${PGPOOLCONF}/pool_hba.conf.sample ${PGPOOLCONF}/pool_hba.conf
RUN touch ${PGPOOLCONF}/pool_passwd


RUN echo "export PATH=${PATH}"                              >> /etc/profile.d/pg_env.sh
RUN echo "export PGSERVICE_NAME=${PGSERVICE_NAME}"          >> /etc/profile.d/pg_env.sh
RUN echo "export PGPOOLSERVICE_NAME=${PGPOOLSERVICE_NAME}"  >> /etc/profile.d/pg_env.sh
RUN echo "export PGDATA=${PGDATA}"                          >> /etc/profile.d/pg_env.sh
RUN echo "export PGPOOLCONF=${PGPOOLCONF}"                  >> /etc/profile.d/pg_env.sh
RUN echo "export CERTDIR=${CERTDIR}"                        >> /etc/profile.d/pg_env.sh

CMD echo "exiting"
