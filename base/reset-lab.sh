#!/usr/bin/env bash

# Set KUBECONFIG
export KUBECONFIG=$HOME/.kube/config

# Update Grafana and Prometheus ENVs
export PROMETHEUS_PORT=30006
export PROMETHEUS_HOSTNAME=localhost
export PROMETHEUS_URI=localhost:${PROMETHEUS_PORT}
export PROMETHEUS_URL="https://${PROMETHEUS_URI}"
export GRAFANA_PORT=30005
export GRAFANA_HOSTNAME=localhost
export GRAFANA_URI=localhost:${GRAFANA_PORT}
export GRAFANA_URL="https://${GRAFANA_URI}"

# Get Current Directory
CURRENTDIR=`pwd`

# Teardown
./base/teardown.sh

# Install
./base/install.sh

# Patch
# ./base/patch.sh

# Deploy Docker Containers
cd ./docker-containers
docker-compose up -d

# Change back to directory
cd $CURRENTDIR

echo ""
echo "KONG MANAGER URL"
echo $KONG_MANAGER_URL