#!/usr/bin/env bash

ORG="Administrator"
DOMAIN="local.network"
DAYS_VALID=30000

mkdir -p ./ssl/private/
mkdir -p ./ssl/certs/

# Create a private certificate authority (CA).
openssl req -x509 -nodes \
    -newkey RSA:2048 \
    -days "$DAYS_VALID" \
    -keyout "./ssl/private/${DOMAIN}_root_ca.key" \
    -out "./ssl/certs/${DOMAIN}_root_ca.crt" \
    -subj "/C=US/ST=State/L=City/O=${ORG}/CN=${DOMAIN}_root_CA"

# Create a private key and a certificate signing request (CSR) for the server.
openssl req -nodes \
    -newkey RSA:2048 \
    -keyout "./ssl/private/${DOMAIN}.key" \
    -out "./ssl/private/${DOMAIN}.csr" \
    -subj "/C=US/ST=State/L=City/O=${ORG}/CN=*.${DOMAIN}"

# Create a certificate for the server.
openssl x509 -req \
    -days "$DAYS_VALID" \
    -CA "./ssl/certs/${DOMAIN}_root_ca.crt" \
    -CAkey "./ssl/private/${DOMAIN}_root_ca.key" \
    -in "./ssl/private/${DOMAIN}.csr" \
    -out "./ssl/certs/${DOMAIN}.crt" \
    -CAcreateserial \
    -extfile <(printf "subjectAltName = DNS:${DOMAIN}, DNS:*.${DOMAIN}, DNS:*.notesnook.${DOMAIN}\nauthorityKeyIdentifier = keyid,issuer\nbasicConstraints = CA:FALSE\nkeyUsage = digitalSignature, keyEncipherment\nextendedKeyUsage=serverAuth")

# Trust the certificates.
sudo cp "./ssl/certs/${DOMAIN}_root_ca.crt" "/etc/pki/ca-trust/source/anchors/${DOMAIN}_root_ca.crt"
sudo cp "./ssl/certs/${DOMAIN}.crt" "/etc/pki/ca-trust/source/anchors/${DOMAIN}.crt"
sudo update-ca-trust
openssl verify "/etc/pki/ca-trust/source/anchors/${DOMAIN}.crt"
