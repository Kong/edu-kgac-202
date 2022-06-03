#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config

sed -i 's/tag: "2.2"/tag: "2.3.1"/g' ./helm/cp-values.yaml
sed -i 's/tag: "2.7-alpine"/tag: "2.8.1.1-alpine"/g' ./helm/dp-values.yaml 
sed -i 's/tag: "2.7-alpine"/tag: "2.8.1.1-alpine"/g' ./helm/cp-values.yaml 

helm upgrade -f ./helm/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=$KONG_PROXY_URI

helm upgrade -f ./helm/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI

watch "kubectl get pods -A"
