#!/usr/bin/env bash

curl https://letsencrypt.org/certs/isrgrootx1.pem >root.pem

curl https://letsencrypt.org/certs/lets-encrypt-r3.pem >intermediate.pem

cat root.pem intermediate.pem > merged.pem