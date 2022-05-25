#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config

cd /home/labuser/kong-course-gateway-ops-for-kubernetes

# Teardown
automation/teardown.sh

# Install
automation/install.sh

# Patch
automation/patch.sh
