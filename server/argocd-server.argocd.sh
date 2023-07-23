#!/bin/bash

rm -f argocd-server.argocd.key.pem argocd-server.argocd.csr.pem argocd-server.argocd.crt.pem

openssl genrsa -out argocd-server.argocd.key.pem

openssl req \
	-new \
	-key argocd-server.argocd.key.pem \
	-nodes \
	-out argocd-server.argocd.csr.pem \
	-subj "/C=BR/ST=Rio de Janeiro/L=Marica/O=Argo CD/OU=Argo CD/CN=localhost" \
	-addext "subjectAltName=DNS:localhost\
,DNS:argocd-server\
,DNS:argocd-server.argocd\
,DNS:argocd-server.argocd.svc\
,DNS:argocd-server.argocd.svc.cluster.local"

openssl x509 \
	-req \
	-in ./argocd-server.argocd.csr.pem \
	-CAkey ./ArgoCDRootCA.key.pem \
	-CA ./ArgoCDRootCA.crt.pem \
	-set_serial -01 \
	-out ./argocd-server.argocd.crt.pem \
	-days 36500 \
	-sha256 \
  -extfile <(printf "subjectAltName=DNS:localhost\
,DNS:argocd-server\
,DNS:argocd-server.argocd\
,DNS:argocd-server.argocd.svc\
,DNS:argocd-server.argocd.svc.cluster.local")
