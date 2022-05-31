#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config

# Remove DP
helm uninstall kong-dp -n kong-dp

# Remove CP
helm uninstall kong -n kong

# Remove Namespaces
kubectl delete ns kong
kubectl delete ns kong-dp

# Delete kind cluster
kind delete cluster --name avl

CURRENTDIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/docker-containers
docker-compose down
cd $CURRENTDIR