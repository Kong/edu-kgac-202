#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config
CURRENTDIR=`pwd`

cd /home/labuser/kong-course-gateway-ops-for-kubernetes

# Teardown
./base/teardown-cluster.sh

# Install
./base/install.sh

# Patch
./base/patch.sh

cd $CURRENTDIR

echo ""
echo "KONG MANAGER URL"
echo $KONG_MANAGER_URL