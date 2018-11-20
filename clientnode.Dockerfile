FROM pgsql-pgpool:10
MAINTAINER m.usama@gmail.com
#copy the client certificates
RUN mkdir /home/postgres/.postgresql 
RUN cp ${CERTDIR}/postgresql.key /home/postgres/.postgresql/postgresql.key
RUN cp ${CERTDIR}/postgresql.crt /home/postgres/.postgresql/postgresql.crt
RUN cp ${CERTDIR}/root.crt /home/postgres/.postgresql/root.crt


RUN chmod 0600 /home/postgres/.postgresql/postgresql.key
RUN chown postgres:postgres /home/postgres/.postgresql/postgresql.key

COPY scripts/client_script.sh /tmp/client_script.sh
RUN chmod +x /tmp/client_script.sh
CMD /tmp/client_script.sh
