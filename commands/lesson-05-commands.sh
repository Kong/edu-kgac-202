#!/usr/bin/env bash

# Reset lab
cd /home/labuser
source ./kong-course-gateway-ops-for-kubernetes/base/reset-lab.sh

# Task: Add a Service to use with OIDC
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/exercises/oidc
cat << EOF > ./httpbin-oidc-plugin.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: httpbin-demo
---
EOF
cat << EOF >> ./httpbin-oidc-plugin.yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: httpbin-oidc
  namespace: httpbin-demo
plugin: openid-connect
config:
  issuer: $KEYCLOAK_CONFIG_ISSUER
  client_id:
  - kong
  client_secret:
  - $CLIENT_SECRET
  response_mode: form_post
  redirect_uri:
  - https://$KEYCLOAK_REDIRECT_URI
  ssl_verify: false
EOF
kubectl apply -f ./httpbin-oidc-plugin.yaml
kubectl apply -f ./httpbin-ingress-oidc.yaml

# Task: Verify Protected Service
http get kongcluster:30000/oidc
http get kongcluster:30000/oidc -a user:password

# Task: View Kong Discovery Information from IDP
http get kongcluster:30001/openid-connect/issuers
http -b get kongcluster:30001/openid-connect/issuers | jq -r .data[].issuer

# Task: Confirm Keycloak is configured for Password Grant
OIDC_PLUGIN_ID=$(http get \
    kongcluster:30001/routes/httpbin-demo.oidc-route.00/plugins/ \
    | jq -r '.data[] | select(.name == "openid-connect") | .id')
http -b get kongcluster:30001/plugins/$OIDC_PLUGIN_ID \
    | jq .config.auth_methods
http -b get kongcluster:30001/plugins/$OIDC_PLUGIN_ID \
    | jq .config.password_param_type

# Task: Provide credentials to Kong and retrieve Access Token
http get kongcluster:30000/oidc -a employee:test
BEARER_TOKEN=$(http kongcluster:30000/oidc -a employee:test | jq -r '.headers.Authorization' | cut -c 7-)
jwt -d $BEARER_TOKEN | jq

# Task: Get a token and authenticate with it
BEARER_TOKEN=$(http -f POST $KEYCLOAK_URL/auth/realms/kong/protocol/openid-connect/token \
                   grant_type=password \
                   client_id=kong \
                   client_secret=$CLIENT_SECRET \
                   username=employee \
                   password=test \
                   | jq -r .access_token)
http get kongcluster:30000/oidc authorization:"Bearer $BEARER_TOKEN"

# Task: Configure a consumer & modify OIDC plugin to require preferred_username
kubectl apply -f ./oidc-consumer.yaml
cp httpbin-oidc-plugin.yaml httpbin-oidc-plugin-claim.yaml
cat << EOF >> httpbin-oidc-plugin-claim.yaml
  consumer_claim: 
  - preferred_username
EOF
kubectl apply -f ./httpbin-oidc-plugin-claim.yaml

# Task: Verify authorization works for a user mapped to a Kong consumer
http get kongcluster:30000/oidc -a employee:test

# Task: Verify authorization is forbidden for a user not mapped to a consumer
http get kongcluster:30000/oidc -a partner:test

# Task: Add & Verify Rate Limiting
kubectl apply -f ./oidc-consumer-rate-limiting.yaml
for ((i=1;i<=5;i++)); do http -h GET kongcluster:30000/oidc -a employee:test; done

# Task: Cleanup
kubectl apply -f ./httpbin-oidc-plugin.yaml
kubectl delete kongplugin employee-rate-limiting -n httpbin-demo
kubectl apply -f ./oidc-consumer.yaml

# Task: Modify the OIDC plugin to search for user roles in a claim
cp ./httpbin-oidc-plugin.yaml ./httpbin-oidc-plugin-realm.yaml
cat << EOF >> ./httpbin-oidc-plugin-realm.yaml
  authenticated_groups_claim:
  - realm_access
  - roles
EOF
kubectl apply -f httpbin-oidc-plugin-realm.yaml

# Task: Configure the ACL plugin and whitelist access to users with the admins role
kubectl apply -f ./httpbin-ingress-oidc-acl.yaml
http get kongcluster:30000/oidc -a employee:test

# Task: Modify the ACL plugin to require users being members of the role demo-service to access the service
cat << EOF | kubectl apply -f -
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: httpbin-acl
  namespace: httpbin-demo
plugin: acl
config:
  allow: 
  - admins
  - demo-service
EOF
http GET kongcluster:30000/oidc -a employee:test

# Task: Cleanup
kubectl delete kongplugin httpbin-oidc -n httpbin-demo
kubectl apply -f ./httpbin-oidc-plugin.yaml

# Task: Modify & verify the plugin to require a scope of admins
cp ./httpbin-oidc-plugin.yaml ./httpbin-oidc-plugin-preferred.yaml
cat << EOF >> ./httpbin-oidc-plugin-preferred.yaml
  consumer_claim: 
  - preferred_username
  consumer_optional: true
EOF
kubectl apply -f ./httpbin-oidc-plugin-preferred.yaml

# Task: Configure Rate Limiting Plugins
kubectl apply -f ./httpbin-ingress-oidc-rate-limiting.yaml
sed -i "s/minute: 3/minute: 1000/g" ./oidc-consumer-rate-limiting.yaml
kubectl apply -f ./oidc-consumer-rate-limiting.yaml

# Task: Verify Rate Limits
for ((i=1;i<=6;i++)); do http -h GET kongcluster:30000/oidc -a partner:test; done
for ((i=1;i<=12;i++)); do http GET kongcluster:30000/oidc -a employee:test; done
