#!/usr/bin/env bash

# Reset lab
cd /home/labuser
source ./kong-course-gateway-ops-for-kubernetes/base/reset-lab.sh

# Task: Configure Service/Route/Consumer/Plugins
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/exercises/vitals
kubectl apply -f ./httpbin-vitals.yaml

# Task: Let's Create Some Traffic 
(for ((i=0;i<64;i++))
     do
       sleep .5
       http -h GET $KONG_PROXY_URI/httpbin?apikey=JanePassword
     done)

# Task: Get Metrics from Vitals API
http kongcluster:30001/default/vitals/status_code_classes?interval=minutes \
    | jq .stats.cluster

# Task: Inspect Kong Vitals Configuration
cat ~/kong-course-gateway-ops-for-kubernetes/base/cp-values.yaml | grep vitals | sort | uniq

# Task: Inspect Prometheus/StatsD Helm Values
cat ~/kong-course-gateway-ops-for-kubernetes/exercises/monitoring/prometheus-values.yaml
cat ~/kong-course-gateway-ops-for-kubernetes/exercises/monitoring/statsd-values.yaml

# Task: Get to GUI for Prometheus
echo $PROMETHEUS_URL

# Task: Let's Create Some Traffic
(for ((i=0;i<256;i++))
     do
       sleep 1
       http -h GET $KONG_PROXY_URI/httpbin?apikey=JanePassword
     done)