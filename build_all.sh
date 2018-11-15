#!/bin/bash
if test -z $1 ; then
    echo "no database name provided for ssl certificates"
    user_name=certuser
else
    user_name=$1
fi
echo "generating certificates for $user_name" user
# build the base docker image
echo "generating server certificates"
mkdir -p certs
cd certs
../scripts/generate_server_ssl_crt.sh ${user_name}
echo "generating client certificates"
../scripts/generate_client_ssl_crt.sh ${user_name}
echo "building containers"
cd ..
docker-compose build


