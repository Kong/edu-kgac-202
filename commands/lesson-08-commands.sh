#!/usr/bin/env bash

# Reset lab
cd $HOME
source ./edu-kgac-202/base/reset-lab.sh

# Task: Gather :30001/ information
http get localhost:30001 | jq '.' > 30001.json
jq -C '.' 30001.json | less -R

# Task: Gather :30001/status information
http get localhost:30001/status | jq '.' > 30001-status.json
jq -C '.' 30001-status.json | less -R

# Task: Kong Log Files in Kubernetes
kubectl describe deployment kong-kong -n kong | grep _LOG | sort | uniq

# Task: Explore Error Logs
./edu-kgac-202/exercises/troubleshooting/kiclogs.sh
./edu-kgac-202/exercises/troubleshooting/dplogs.sh

# Task: Explore Startup System Log
CP_POD=`kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}'`
kubectl exec $CP_POD -it -n kong -c proxy -- /bin/sh
kong reload --v
kong reload --vv
exit

# Task: Use Debug Header to see used Service/Route
kubectl apply -f ~/edu-kgac-202/base/httpbin-ingress.yaml
http -h get localhost:30000/httpbin Kong-Debug:1

# Task: Use Granular Tracing to Log Details
kubectl apply -f ~/edu-kgac-202/exercises/vitals/httpbin-vitals.yaml
cat ~/edu-kgac-202/base/dp-values.yaml | grep tracing

# Task: Use Granular Tracing to Log Details
http -h get localhost:30000/httpbin apikey:JanePassword X-Trace:1 | head -1
http -h get localhost:30000/httpbin X-Trace:1 | head -1
~/edu-kgac-202/exercises/troubleshooting/dplogs.sh

# Task: Explore Audit Logs
http get localhost:30001/license/report
http get localhost:30001/audit/requests

# Task: Network troubleshooting with cURL
curl -svv --fail --trace-time https://api.github.com/repos/kong/kong | jq
curl -o /dev/null --silent --show-error --write-out '\n\nlookup: %{time_namelookup}\nconnect: %{time_connect}\nappconnect: %{time_appconnect}\npretransfer: %{time_pretransfer}\nredirect: %{time_redirect}\nstarttransfer: %{time_starttransfer}\ntotal: %{time_total}\nsize: %{size_download}\n\n' 'https://api.github.com/repos/kong/kong'

# Task: Broken Lab Scenario 1 - 502 Error
cd ~/edu-kgac-202/exercises/troubleshooting
kubectl delete namespace httpbin-demo
kubectl apply -f ./broken-lab-1.yaml
http --headers get $KONG_PROXY_URI/httpbin?apikey=JanePassword | head -1
http --headers get $KONG_PROXY_URI/httpbin?apikey=JanePassword
./dplogs.sh

# Broken Lab Scenario 1: Solution
sed -i 's/konghq.com\/protocol: "https"/konghq.com\/protocol: "http"/g' ./broken-lab-1.yaml
kubectl apply -f ./broken-lab-1.yaml

# Task: Broken Lab Scenario 2 - Headers Issue
kubectl delete namespace httpbin-demo
kubectl apply -f ./broken-lab-2.yaml
http get $KONG_PROXY_URI/httpbin X-with-ID:true
./dplogs.sh
./kiclogs.sh
./cplogs.sh

# Broken Lab Scenario 2: Solution
sed -i 's/generator: tracker/generator: uuid/g' ./broken-lab-2.yaml
sed -i '/konghq.com\/plugins: "httpbin-request-transform"/d' ./broken-lab-2.yaml
kubectl apply -f ./broken-lab-2.yaml

# Task: Broken Lab Scenario 3 - Plugin Issue
kubectl delete namespace httpbin-demo
kubectl apply -f ./broken-lab-3.yaml
http get $KONG_PROXY_URI/httpbin
http get $KONG_PROXY_URI/httpbin apikey:JanePassword
./dplogs.sh
./kiclogs.sh
./cplogs.sh

# Broken Lab Scenario 3: Solution 
sed -i 's/namespace: default/namespace: httpbin-demo/g' ./broken-lab-3.yaml
kubectl apply -f ./broken-lab-3.yaml
kubectl delete kongplugin httpbin-auth -n default
http GET $KONG_PROXY_URI/httpbin
http GET $KONG_PROXY_URI/httpbin apikey:JanePassword