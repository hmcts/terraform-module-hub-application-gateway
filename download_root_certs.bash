#!/usr/bin/env bash
cd .terraform/modules/app-gw
#grabing the public root CA 
pwd
ls
curl https://letsencrypt.org/certs/isrgrootx1.pem >root.pem
#grabing the public intermediate CA
curl https://letsencrypt.org/certs/lets-encrypt-r3.pem >intermediate.pem

cat root.pem intermediate.pem >merged.pem
chmod u+x merged.pem
ls
pwd