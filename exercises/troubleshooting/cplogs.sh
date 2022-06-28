#!/usr/bin/env bash

# Get CP Pod from kubectl
CP_POD=`kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}'`

# Show logs
kubectl logs $CP_POD -n kong
