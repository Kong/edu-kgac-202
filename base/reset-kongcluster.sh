#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config
CURRENTDIR=`pwd`

cd /home/labuser/kong-course-gateway-ops-for-kubernetes

# Teardown
./base/teardown.sh

# Install
./automation/install.sh

# Patch
./automation/patch.sh

# Deploy Docker Containers
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/docker-containers
docker-compose up -d

cd $CURRENTDIR