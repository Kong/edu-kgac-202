#!/usr/bin/env bash
CURRENT_DIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/apps/jwt

# Generate keypair
ssh-keygen -N "" -f ./jane
export JANE_PUB_64=`ssh-keygen -f ./jane.pub -e -m pem | base64 -w0`

# Create jane-consumer-jwt.yaml
cat << EOF > jane-consumer-jwt.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: jane-jwt
  namespace: kong-dp
type: Opaque
data:
  key: S0VZX1RFWFQ=
  kongCredType: and0
  algorithm: UlMyNTY=
  rsa_public_key: $JANE_PUB_64
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