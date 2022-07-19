#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config
CURRENTDIR=`pwd`

cd /home/labuser/kong-course-gateway-ops-for-kubernetes

# Teardown
./base/teardown.sh

# Install
./base/install.sh

# Patch
./base/patch.sh

# Deploy Docker Containers
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/docker-containers
docker-compose up -d

cd $CURRENTDIR

echo ""
echo "KONG MANAGER URL"
echo $KONG_MANAGER_URL