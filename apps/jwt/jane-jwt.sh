#!/usr/bin/env bash
CURRENT_DIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/apps/jwt

# Generate keypair
rm -f ./jane
rm -f ./jane.pub
ssh-keygen -N "" -f ./jane
export JANE_PUB=`cat ./jane.pub`

# Create jane-consumer-jwt.yaml
cat << EOF > jane-consumer-jwt.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: jane-jwt
  namespace: kong-dp
type: Opaque
stringData:
  key: jane-issuer
  kongCredType: jwt
  algorithm: RS256
  rsa_public_key: $JANE_PUB
---
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: jane
  namespace: kong-dp
  annotations:
    kubernetes.io/ingress.class: kong
username: jane
credentials:
  - jane-jwt
EOF

kubectl apply -f ./jane-consumer-jwt.yaml

# Back to starting dir
cd $CURRENT_DIR