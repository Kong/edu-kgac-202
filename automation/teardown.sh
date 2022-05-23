#!/usr/bin/env bash

# Remove DP
helm uninstall kong-dp -n kong-dp

# Remove CP
helm uninstall kong -n kong

# Remove Namespaces
kubectl delete ns kong
kubectl delete ns kong-dp

# Delete kind cluster
kind delete cluster --name avl