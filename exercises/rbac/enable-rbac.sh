#!/usr/bin/env bash

CURRENTDIR=`pwd`
cd /home/labuser/edu-kgac-202/

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

yq -i '.env.admin_gui_url = env(KONG_MANAGER_URL)' ./exercises/rbac/cp-values-rbac.yaml
yq -i '.env.admin_api_url = env(KONG_ADMIN_API_URL)' ./exercises/rbac/cp-values-rbac.yaml
yq -i '.env.admin_api_uri = env(KONG_ADMIN_API_URI)' ./exercises/rbac/cp-values-rbac.yaml
yq -i '.env.proxy_url = env(KONG_PROXY_URL)' ./exercises/rbac/cp-values-rbac.yaml
yq -i '.env.portal_api_url = env(KONG_PORTAL_API_URL)' ./exercises/rbac/cp-values-rbac.yaml
yq -i '.env.portal_gui_host = env(KONG_PORTAL_GUI_HOST)' ./exercises/rbac/cp-values-rbac.yaml

helm upgrade -f ./exercises/rbac/cp-values-rbac.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI

watch "kubectl get pods -n kong"
cd $CURRENTDIR