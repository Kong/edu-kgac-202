#!/usr/bin/env bash

# Enable RBAC
cat << EOF > admin_gui_session_conf
{
    "cookie_name":"admin_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":true,
    "cookie_lifetime":60,
    "storage":"kong"
}
EOF
kubectl create secret generic kong-session-config -n kong \
--save-config \
--dry-run=client \
--from-file=admin_gui_session_conf \
-o yaml | \
kubectl apply -f -

kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kong

helm upgrade -f ./helm/cp-values-rbac.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI

kubectl patch deployment kong-kong -n kong -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"proxy\",\"env\":[\
{\"name\":\"KONG_ADMIN_API_URI\",\"value\":\"${KONG_ADMIN_API_URI}\"},\
{\"name\":\"KONG_ADMIN_GUI_URL\",\"value\":\"${KONG_ADMIN_GUI_URL}\"},\
{\"name\":\"KONG_PORTAL_GUI_HOST\",\"value\":\"${KONG_PORTAL_GUI_HOST}\"},\
{\"name\":\"KONG_PORTAL_API_URL\",\"value\":\"${KONG_PORTAL_API_URL}\"}\
]}]}}}}"

# kubectl patch deployment kong-kong -n kong -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"proxy\",\"env\":[\
# {\"name\":\"KONG_ENFORCE_RBAC\",\"value\":\"on\"},\
# {\"name\":\"KONG_ADMIN_GUI_AUTH\",\"value\":\"basic-auth\"},\
# {\"name\":\"KONG_ADMIN_API_URI\",\"value\":\"${KONG_ADMIN_API_URI}\"},\
# {\"name\":\"KONG_ADMIN_GUI_URL\",\"value\":\"${KONG_ADMIN_GUI_URL}\"},\
# {\"name\":\"KONG_PORTAL_GUI_HOST\",\"value\":\"${KONG_PORTAL_GUI_HOST}\"},\
# {\"name\":\"KONG_PORTAL_API_URL\",\"value\":\"${KONG_PORTAL_API_URL}\"}\
# ]}]}}}}"
