#!/usr/bin/env bash
CURRENT_DIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/apps/jwt

# Generate keypair
rm -f ./jane
rm -f ./jane.pub
ssh-keygen -N "" -f ./jane
export JANE_PUB=`ssh-keygen -f ./jane.pub -e -m pem`

# Create jane-consumer.yaml
cat << EOF > jane-consumer.yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: jane
  namespace: kong-dp
  annotations:
    kubernetes.io/ingress.class: kong
username: jane
EOF
kubectl apply -f ./jane-consumer.yaml

# Create jane-secret.yaml
kubectl create secret generic jane-jwt \
  --from-literal=kongCredType=jwt  \
  --from-literal=key="jane-issuer" \
  --from-literal=algorithm=RS256 \
  --from-literal=rsa_public_key="$JANE_PUB" \
  -o yaml --dry-run=client > ./jane-secret.yaml
kubectl apply -f ./jane-secret.yaml

# Update Jane Consumer
cat << EOF > jane-consumer-jwt.yaml
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