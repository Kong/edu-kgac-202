#!/bin/bash

source ~/.bashrc
export PUBLICIP=$(curl -s http://checkip.amazonaws.com)
export KONGHOSTNAME="$STRIGO_RESOURCE_DNS"
export KONG_ADMIN_API_URI=http://$KONGHOSTNAME:30001
export KONG_ADMIN_GUI_URL=http://$KONGHOSTNAME:30002
export KONG_PORTAL_GUI_HOST=$KONGHOSTNAME:30003
export KONG_PORTAL_API_URL=http://$KONGHOSTNAME:30004
# export KONG_LICENSE_DATA="$(cat /usr/local/kong/license.json)"
export KONG_PROXY_URI="http://$KONGHOSTNAME:30000"

