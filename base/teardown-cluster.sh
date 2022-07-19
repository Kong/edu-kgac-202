#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config

# Remove DP
helm uninstall kong-dp -n kong-dp --wait

# Remove CP
helm uninstall kong -n kong --wait

# Remove Namespaces
kubectl delete ns kong
kubectl delete ns kong-dp