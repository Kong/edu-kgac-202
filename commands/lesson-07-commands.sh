#!/usr/bin/env bash

# Reset lab
cd /home/labuser
source ./kong-course-gateway-ops-for-kubernetes/base/reset-lab.sh

# Task: Configure Service/Route/Plugin/Consumer
cd ~/kong-course-gateway-ops-for-kubernetes/exercises/adv-plugins
kubectl apply -f ./httpbin-ingress-jane.yaml

# Task: Configure Rate Limiting Advanced Plugin
kubectl apply -f ./rate-limiting-adv.yaml

# Task: Create Traffic with Advanced Rate Limiting Plugin Enabled
for ((i=0;i<32;i++))
  do
    sleep 1
    http get $KONG_PROXY_URI/httpbin?apikey=JanePassword
  done

# Task: Configure Request Transformer Advanced Plugin
kubectl apply -f ./request-transform.yaml

# Task: Create Request to See Request Headers
http get $KONG_PROXY_URI/httpbin?apikey=JanePassword

# Task: Configure Response Transformer Advanced Plugin
kubectl apply -f ./response-transform.yaml

# Task: Create Request to See Response Headers/Body
http get $KONG_PROXY_URI/httpbin?apikey=JanePassword

# Task: Configure jq Plugin
http -b get kongcluster:30000/httpbin?apikey=JanePassword
kubectl apply -f ./jq.yaml

# Task: Create Request to See Response Body
http -b get $KONG_PROXY_URI/httpbin?apikey=JanePassword

# Task: Use Transformer Plugin
http get $KONG_PROXY_URI/httpbin

# Task: Configure Exit Transformer Plugin
kubectl apply -f ./exit-transform.yaml

# Task: Create Request to See Response Header/Body Transformation
http get $KONG_PROXY_URI/httpbin

# Task: Enable the Prometheus Plugin & Generate Traffic
kubectl apply -f ./prometheus-adv.yaml
for ((i=0;i<32;i++))
    do
      sleep 1
      http -h GET $KONG_PROXY_URI/httpbin?apikey=JanePassword > /dev/null 2>&1
      sleep 1
      http -h GET $KONG_PROXY_URI/httpbin > /dev/null 2>&1
    done &

# Task: Get Prometheus Plugin Metrics through API
DP_POD=`kubectl get pods --selector=app=kong-dp-kong -n kong-dp -o jsonpath='{.items[*].metadata.name}'`
CP_POD=`kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}'`
kubectl expose pod $DP_POD --name kong-dp-status -n kong-dp --port=8100 --target-port=8100
kubectl expose pod $CP_POD --name kong-status -n kong --port=8100 --target-port=8100
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot
http kong-dp-status.kong-dp.svc.cluster.local:8100/metrics | grep httpbin
http kong-status.kong.svc.cluster.local:8100/metrics | grep httpbin
http kong-status.kong.svc.cluster.local:8100/metrics
exit

# Task: Get Metrics from Prometheus
echo $PROMETHEUS_URL