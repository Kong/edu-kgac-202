#!/usr/bin/env bash

# Reset lab
cd /home/labuser
source ./edu-kgac-202/base/reset-lab.sh

# Task: Deploy an Ingress for our httpbin app
cd ./edu-kgac-202
kubectl apply -f ./base/httpbin-ingress.yaml
http --headers get $KONG_PROXY_URL/httpbin

# Task: Configure Rate Limiting and key-auth Plugins and add Jane the Consumer
kubectl apply -f ./exercises/rate-limiting/httpbin-ingress-rates-key.yaml
kubectl apply -f ./exercises/rate-limiting/jane-consumer.yaml

# Task: Create Some Traffic for User
(for ((i=1;i<=20;i++))
     do
     sleep 1
     http --headers $KONG_PROXY_URL/httpbin?apikey=JanePassword
   done)

# Task: Reset httpbin service
cd ~/edu-kgac-202/exercises/jwt
kubectl delete ns httpbin-demo
kubectl apply -f ../../base/httpbin-ingress.yaml
http --headers get $KONG_PROXY_URL/httpbin

# Task: Enable JWT Plugin for our Service
kubectl apply -f ./httpbin-ingress-jwt.yaml
http --headers get $KONG_PROXY_URL/httpbin

# Task: Create a consumer and assign JWT credentials
cat << EOF > jane-consumer.yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: jane
  namespace: httpbin-demo
  annotations:
    kubernetes.io/ingress.class: kong
username: jane
EOF
kubectl apply -f ./jane-consumer.yaml
openssl genrsa -out ./jane.pem 2048
openssl rsa -in ./jane.pem -outform PEM -pubout -out ./jane.pub
kubectl create secret generic jane-jwt -n httpbin-demo \
  --from-literal=kongCredType=jwt  \
  --from-literal=key="jane-issuer" \
  --from-literal=algorithm=RS256 \
  --from-file=rsa_public_key=./jane.pub \
  -o yaml --dry-run=client > ./jane-secret.yaml
kubectl apply -f ./jane-secret.yaml
cat << EOF > jane-consumer-jwt.yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: jane
  namespace: httpbin-demo
  annotations:
    kubernetes.io/ingress.class: kong
username: jane
credentials:
  - jane-jwt
EOF
kubectl apply -f ./jane-consumer-jwt.yaml

# Task: Build our JWT
export JANE_HEADER=`echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'`
export JANE_PAYLOAD=`echo -n '{"iss":"jane-issuer"}' | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'`
export JANE_HEADER_PAYLOAD=$JANE_HEADER.$JANE_PAYLOAD
export JANE_PEM=`cat ./jane.pem`
export JANE_SIG=`openssl dgst -sha256 -sign <(echo -n "${JANE_PEM}") <(echo -n "${JANE_HEADER_PAYLOAD}") | openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'`
export JANE_TOKEN=$JANE_HEADER.$JANE_PAYLOAD.$JANE_SIG
echo $JANE_TOKEN

# Task: Consume the service with JWT credentials
http -h get kongcluster:30000/httpbin
http -h get kongcluster:30000/httpbin Authorization:"Bearer $JANE_TOKEN"

# Task: Delete the httpbin-demo Namespace
cd ~/edu-kgac-202/exercises/mtls
kubectl delete ns httpbin-demo

# Task: Create a self-signed certificate 
./create-certificate.sh

# Task: Set up public and a private services & routes
kubectl apply -f ./httpbin-ingress.yaml

# Task: Verify traffic is being proxied
http --verify=no GET https://kongcluster:30443/public
http --verify=no GET https://kongcluster:30443/confidential

# Task: Implement the mTLS plugin to Kong
kubectl create secret generic httpbin-mtls -n httpbin-demo \
  --from-literal=id=cce8c384-721f-4f58-85dd-50834e3e733a \
  --from-file=cert=/home/labuser/.certificates/ca.cert.pem \
  -o yaml --dry-run=client > ./httpbin-mtls-secret.yaml
kubectl apply -f ./httpbin-mtls-secret.yaml
kubectl label secret httpbin-mtls -n httpbin-demo konghq.com/ca-cert='true'
kubectl annotate secret httpbin-mtls -n httpbin-demo \
  kubernetes.io/ingress.class=kong
kubectl apply -f ./httpbin-ingress-mtls.yaml

# Task: Verify access for private service without a certificate
http --verify=no https://kongcluster:30443/confidential

# Task: Create a consumer
kubectl create secret generic mtls-consumer -n httpbin-demo \
  --from-literal=kongCredType=key-auth \
  --from-file=key=/home/labuser/.certificates/client.key \
  -o yaml --dry-run=client > ./mtls-consumer-secret.yaml
kubectl apply -f ./mtls-consumer-secret.yaml
kubectl apply -f ./mtls-consumer.yaml

# Task: Verify access for private service with a certificate
http --verify=no \
  --cert=/home/labuser/.certificates/client.crt \
  --cert-key=/home/labuser/.certificates/client.key \
  https://kongcluster:30443/confidential

# Task: Verify public route is unaffected 
http --verify=no GET https://kongcluster:30443/public

# Task: Configure and Test Rate Limiting
kubectl apply -f ./mtls-consumer-rate-limiting.yaml
(for ((i=1;i<=15;i++))
   do
     http -h --verify=no --cert=/home/labuser/.certificates/client.crt \
          --cert-key=/home/labuser/.certificates/client.key \
          https://kongcluster:30443/confidential \
          | head -1
    done)
