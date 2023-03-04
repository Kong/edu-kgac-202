#!/bin/bash

source ~/.bashrc
export PUBLICIP=$(curl -s http://checkip.amazonaws.com)
export KONG_ADMIN_API_URI=http://$STRIGO_RESOURCE_DNS:30001
export KONG_ADMIN_GUI_URL=http://$STRIGO_RESOURCE_DNs:30002
export KONG_PORTAL_GUI_HOST=$STRIGO_RESOURCE_DNS:30003
export KONG_PORTAL_API_URL=http://$STRIGO_RESOURCE_DNS:30004
# export KONG_LICENSE_DATA="$(cat /usr/local/kong/license.json)"
export KONGHOSTNAME="$STRIGO_RESOURCE_DNS"
export KONG_PROXY_URI="http://$STRIGO_RESOURCE_DNS:30000"

export KEYCLOAK_URI="http://$STRIGO_RESOURCE_DNS:8080/auth"
export KEYCLOAK_REDIRECT_URI="http://$STRIGO_RESOURCE_DNS:30000/oidc"
export KEYCLOAK_CONFIG_ISSUER="http://$STRIGO_RESOURCE_DNS:8080/auth/realms/kong/.well-known/openid-configuration"
export CLIENT_SECRET="$(jq '.clients[] | select(.clientId == "kong")' /home/ubuntu/edu-kgac-202/exercises/oidc/kong_realm_template.json | jq .secret | xargs)"
export KEYCLOAK_URL="http://$STRIGO_RESOURCE_DNS:8080"