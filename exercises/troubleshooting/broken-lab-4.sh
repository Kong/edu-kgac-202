#!/usr/bin/env bash

# Get current directory
CURRENTDIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/

# Delete httpbin-demo namespace
kubectl delete namespace httpbin-demo

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

helm upgrade -f ./exercises/troubleshooting/dp-broken-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=$KONG_PROXY_URI

# Deploy some configs


# Change back to source directory
cd $CURRENTDIR
