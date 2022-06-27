#!/usr/bin/env bash
CURRENT_DIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/exercises/jwt

# Generate keypair
rm -f ./jane
rm -f ./jane.pub
rm -f ./jane.pem
openssl genrsa -out ./jane.pem 2048
openssl rsa -in ./jane.pem -outform PEM -pubout -out ./jane.pub

# Create jane-consumer.yaml
cat << EOF > jane-consumer.yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: jane
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
  --from-file=rsa_public_key=./jane.pub \
  -o yaml --dry-run=client > ./jane-secret.yaml
kubectl apply -f ./jane-secret.yaml

# Update Jane Consumer
cat << EOF > jane-consumer-jwt.yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: jane
  annotations:
    kubernetes.io/ingress.class: kong
username: jane
credentials:
  - jane-jwt
EOF
kubectl apply -f ./jane-consumer-jwt.yaml

export JANE_HEADER=`echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'`
export JANE_PAYLOAD=`echo -n '{"iss":"jane-issuer"}' | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'`
export JANE_HEADER_PAYLOAD=$JANE_HEADER.$JANE_PAYLOAD
export JANE_PEM=`cat ./jane.pem`
export JANE_SIG=`openssl dgst -sha256 -sign <(echo -n "${JANE_PEM}") <(echo -n "${JANE_HEADER_PAYLOAD}") | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'`
export JANE_TOKEN=$JANE_HEADER.$JANE_PAYLOAD.$JANE_SIG

# Back to starting dir
cd $CURRENT_DIR