#!/usr/bin/env bash
sed -i 's/tag: "2.2"/tag: "2.3"/g' ./helm/cp-values.yaml
sed -i 's/tag: "2.7-alpine"/tag: "2.8-alpine"/g' ./helm/dp-values.yaml 
sed -i 's/tag: "2.7-alpine"/tag: "2.8-alpine"/g' ./helm/cp-values.yaml 

helm upgrade -f ./helm/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=$KONG_PROXY_URI

helm upgrade -f ./helm/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI

# Update Deployment Environment Variables
# kubectl patch deployment kong-kong -n kong -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"proxy\",\"env\":[\
# {\"name\":\"KONG_ADMIN_API_URI\",\"value\":\"${KONG_ADMIN_API_URI}\"},\
# {\"name\":\"KONG_ADMIN_GUI_URL\",\"value\":\"${KONG_ADMIN_GUI_URL}\"},\
# {\"name\":\"KONG_PORTAL_GUI_HOST\",\"value\":\"${KONG_PORTAL_GUI_HOST}\"},\
# {\"name\":\"KONG_PORTAL_API_URL\",\"value\":\"${KONG_PORTAL_API_URL}\"}\
# ]}]}}}}"

watch "kubectl get pods -A"
