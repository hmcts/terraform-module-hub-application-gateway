#!/usr/bin/env bash
cd .terraform/modules/app-gw
#grabing the public root CA 
# pwd
# ls
# curl https://letsencrypt.org/certs/isrgrootx1.pem >root.pem
# #grabing the public intermediate CA
# curl https://letsencrypt.org/certs/lets-encrypt-r3.pem >intermediate.pem

# cat root.pem intermediate.pem >merged.pem
# chmod u+x merged.pem
# ls
# pwd

	curl http://r3.i.lencr.org/ >signer.der

	openssl x509 -inform der -in signer.der -out signer.pem

	curl http://x1.i.lencr.org/ >signer2.der

	openssl x509 -inform der -in signer2.der -out signer2.pem


	cat signer.pem signer2.pem > merged.pem

    cat merged.pem