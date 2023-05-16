#!/usr/bin/env bash

# Reset lab
cd /home/labuser
source ./edu-kgac-202/base/reset-lab.sh

# Examine the sample kic workspace yamls in the repo
cat ./edu-kgac-202/base/kic-workspace-a.yaml

# Install the helm chart and update
helm repo add kong https://charts.konghq.com
helm repo update

# Install the new KIC
helm install --version 2.20.2 -f ./edu-kgac-202/base/kic-workspace-a.yaml kic-workspace-a kong/kong -n kong

# Verify the new ingress class
kubectl get ingressclasses

# View the deployments
kubectl get deployments -n kong

# Delete the KIC
helm uninstall kic-workspace-a -n kong