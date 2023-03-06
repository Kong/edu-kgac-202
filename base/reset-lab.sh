#!/usr/bin/env bash

until [ -f /home/ubuntu/.initcomplete ]
do
  sleep 2
  echo "Waiting for vm to initialise"
done

# Set KUBECONFIG
export KUBECONFIG=/home/ubuntu/.kube/config

# Update Grafana and Prometheus ENVs
export PROMETHEUS_PORT=30006
export PROMETHEUS_HOSTNAME=${KONGHOSTNAME}
export PROMETHEUS_URI=${PROMETHEUS_HOSTNAME}
export PROMETHEUS_URL="http://${PROMETHEUS_HOSTNAME}:${PROMETHEUS_PORT}"
export GRAFANA_PORT=30005
export GRAFANA_HOSTNAME=${KONGHOSTNAME}
export GRAFANA_URI=${GRAFANA_HOSTNAME}
export GRAFANA_URL="http://${GRAFANA_HOSTNAME}:${GRAFANA_PORT}"

# Get Current Directory
CURRENTDIR=$(pwd)

cd /home/ubuntu/edu-kgac-202

# Teardown
./base/teardown.sh

# Install
./base/install.sh

# Patch
./base/patch.sh

# Deploy Docker Containers
# cd /home/ubuntu/edu-kgac-202/docker-containers
# docker-compose up -d

# Change back to directory
cd $CURRENTDIR

echo ""
echo "KONG MANAGER URL"
echo $KONG_MANAGER_URL