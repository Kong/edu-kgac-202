#!/bin/bash

source ~/.bashrc
export PUBLICIP=$(curl -s http://checkip.amazonaws.com)
export KONG_ADMIN_API_URI=http://$STRIGO_RESOURCE_DNS:30001
export KONG_ADMIN_GUI_URL=http://$STRIGO_RESOURCE_DNs:30002
export KONG_PORTAL_GUI_HOST=$STRIGO_RESOURCE_DNS:30003
export KONG_PORTAL_API_URL=http://$STRIGO_RESOURCE_DNS:30004
# export KONG_LICENSE_DATA="$(cat /usr/local/kong/license.json)"
export KONGHOSTNAME="$STRIGO_RESOURCE_DNS"

export KEYCLOAK_URI="http://$STRIGO_RESOURCE_DNS:8080/auth"
export KEYCLOAK_REDIRECT_URI="http://$STRIGO_RESOURCE_DNS:8080/echo-request"
export KEYCLOAK_CONFIG_ISSUER="http://keycloak:8080/auth/realms/kong/.well-known/openid-configuration"
export CLIENT_SECRET="$(jq '.clients[] | select(.clientId == "kong")' /home/ubuntu//edu-kgac-202/exercises/oidc/kong_realm_template.json | jq .secret | xargs)"
