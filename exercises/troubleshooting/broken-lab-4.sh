#!/usr/bin/env bash

# Get current directory
CURRENTDIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/

# Delete httpbin-demo namespace
kubectl delete namespace httpbin-demo kong-dp

# Upgrade Kong CP with Broken Values
sed -i "s/admin_gui_url:.*/admin_gui_url: https:\/\/$KONG_MANAGER_URI/g" ./exercises/troubleshooting/cp-broken-values.yaml
sed -i "s/admin_api_url:.*/admin_api_url: https:\/\/$KONG_ADMIN_API_URI/g" ./exercises/troubleshooting/cp-broken-values.yaml
sed -i "s/admin_api_uri:.*/admin_api_uri: $KONG_ADMIN_API_URI/g" ./exercises/troubleshooting/cp-broken-values.yaml
sed -i "s/proxy_url:.*/proxy_url: https:\/\/$KONG_PROXY_URI/g" ./exercises/troubleshooting/cp-broken-values.yaml
sed -i "s/portal_api_url:.*/portal_api_url: https:\/\/$KONG_PORTAL_API_URI/g" ./exercises/troubleshooting/cp-broken-values.yaml
sed -i "s/portal_gui_host:.*/portal_gui_host: $KONG_PORTAL_GUI_HOST/g" ./exercises/troubleshooting/cp-broken-values.yaml

helm upgrade -f ./exercises/troubleshooting/cp-broken-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI 

# Deploy Kong Data Plane
kubectl create namespace kong-data-plane
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-data-plane
kubectl create secret generic kong-enterprise-license -n kong-data-plane --from-file=license=/etc/kong/license.json
helm install -f ./exercises/troubleshooting/dp-broken-values.yaml kong-data-plane kong/kong -n kong-data-plane \
--set proxy.ingress.hostname=${KONG_PROXY_URI}

# Wait for Kong DP Pods
while [[ -z $(kubectl get pods --selector=app=kong-data-plane-kong -n kong-data-plane -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) ]]; do
  echo "Waiting for kong data plane pod to exist..."
  sleep 1
done
WAIT_POD=`kubectl get pods --selector=app=kong-data-plane-kong -n kong-data-plane -o jsonpath='{.items[*].metadata.name}'`
echo "Kong data plane pod exists and now waiting for it to come online..."
kubectl wait --for=condition=Ready --timeout=300s pod $WAIT_POD -n kong-data-plane

# Deploy some configs
kubectl apply -f ./exercises/troubleshooting/broken-lab-4.yaml
source ./exercises/jwt/jane-jwt.sh

# Change back to source directory
cd $CURRENTDIR
