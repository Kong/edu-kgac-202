#!/usr/bin/env bash

# Get DP Pod from kubectl
DP_POD=`kubectl get pods --selector=app=kong-dp-kong -n kong-dp -o jsonpath='{.items[*].metadata.name}'`

# Expose Pod on port 8100
kubectl expose pod $DP_POD --name kong-dp-status -n kong-dp --port=8100 --target-port=8100 > /dev/null 2>&1

# Show Metrics from Status
kubectl run tmp-shell --rm -it --image nicolaka/netshoot -- bash -c "http kong-dp-status.kong-dp.svc.cluster.local:8100/metrics"
