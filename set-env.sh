#!/bin/bash

source ~/.bashrc
export PUBLICIP=$(curl -s http://checkip.amazonaws.com)
export KONG_ADMIN_API_URI=http://$STRIGO_RESOURCE_DNS:30001
export KONG_ADMIN_GUI_URL=http://$STRIGO_RESOURCE_DNs:30002
export KONG_PORTAL_GUI_HOST=$STRIGO_RESOURCE_DNS:30003
export KONG_PORTAL_API_URL=http://$STRIGO_RESOURCE_DNS:30004
# export KONG_LICENSE_DATA="$(cat /usr/local/kong/license.json)"
export KONGHOSTNAME="$STRIGO_RESOURCE_DNS"