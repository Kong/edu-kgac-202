#!/usr/bin/env bash

# Get DP Pod from kubectl
DP_POD=`kubectl get pods --selector=app=kong-dp-kong -n kong-dp -o jsonpath='{.items[*].metadata.name}'`

# Show logs
kubectl logs $DP_POD -n kong-dp
