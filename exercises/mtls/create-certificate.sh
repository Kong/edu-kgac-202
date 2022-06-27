#!/usr/bin/env bash
CERT_FOLDER=/home/labuser/.certificates
export OPENSSL_CONF=/home/labuser/kong-course-gateway-ops-for-kubernetes/exercises/mtls/openssl.cnf
mkdir -p ${CERT_FOLDER}
pushd ${CERT_FOLDER}
touch index.txt
echo 1337 > serial

openssl rand -writerand .rnd
openssl genrsa -aes256 -out ca.key.pem -passout pass:konglabs 4096
chmod 400 ca.key.pem
openssl req -config /home/labuser/kong-course-gateway-ops-for-kubernetes/exercises/mtls/openssl.cnf -key ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -passin 'pass:konglabs' -subj "/C=WD/ST=Earth/L=Global/O=Kong Inc./CN=Kong CA" -out ca.cert.pem

openssl genrsa -out client.key 2048
openssl req -new -subj "/emailAddress=demo@example.com/CN=example.com/O=Kong Inc./OU=Kong Academy/C=WD/ST=Earth/L=Global" -key client.key -out client.csr

# Make sure that there are the files in the computer: openssl.cnf, index.txt and serial
openssl ca -batch -config /home/labuser/kong-course-gateway-ops-for-kubernetes/exercises/mtls/openssl.cnf -extensions usr_cert -cert ca.cert.pem -keyfile ca.key.pem -passin 'pass:konglabs' -in client.csr -out client.crt

popd