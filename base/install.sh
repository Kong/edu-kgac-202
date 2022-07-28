#!/usr/bin/env bash

# Pull Docker Certs
cd /home/labuser
./setup-docker.sh

# Create Kind Cluster
KIND_HOST=`getent hosts kongcluster | cut -d " " -f1`
cat << EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: avl
networking:
  apiServerAddress: ${KIND_HOST}
  apiServerPort: 8443
  disableDefaultCNI: true
  podSubnet: "192.168.0.0/16"
nodes:
  - role: control-plane
    extraPortMappings:
    - listenAddress: "0.0.0.0"
      protocol: TCP
      hostPort: 30000
      containerPort: 30000
    - listenAddress: "0.0.0.0"
      protocol: TCP
      hostPort: 30001
      containerPort: 30001
    - listenAddress: "0.0.0.0"
      protocol: TCP
      hostPort: 30002
      containerPort: 30002
    - listenAddress: "0.0.0.0"
      protocol: TCP
      hostPort: 30003
      containerPort: 30003
    - listenAddress: "0.0.0.0"
      protocol: TCP
      hostPort: 30004
      containerPort: 30004
    - listenAddress: "0.0.0.0"
      protocol: TCP
      hostPort: 30005
      containerPort: 30005
    - listenAddress: "0.0.0.0"
      protocol: TCP
      hostPort: 30006
      containerPort: 30006
    - listenAddress: "0.0.0.0"
      protocol: TCP
      hostPort: 30443
      containerPort: 30443
EOF

kind create cluster --config kind-config.yaml
export KUBECONFIG=/home/labuser/.kube/config
kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

# K8s resources, prometheus, grafana, and statsd
kubectl create namespace monitoring
kubectl create namespace kong
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install -f /home/labuser/kong-course-gateway-ops-for-kubernetes/exercises/monitoring/prometheus-values.yaml prometheus prometheus-community/kube-prometheus-stack -n monitoring --wait
helm install -f /home/labuser/kong-course-gateway-ops-for-kubernetes/exercises/monitoring/statsd-values.yaml statsd prometheus-community/prometheus-statsd-exporter -n monitoring --wait
helm install redis bitnami/redis -n kong --set auth.enabled=false

# Create Keys and Certs, Namespace, and Load into K8s
cd /home/labuser/kong-course-gateway-ops-for-kubernetes
openssl rand -writerand .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong

# Load License
kubectl create secret generic kong-enterprise-license -n kong --from-file=license=/etc/kong/license.json

# Create Manager Config
cat << EOF > admin_gui_session_conf
{
    "cookie_name":"admin_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":false,
    "storage":"kong"
}
EOF
kubectl create secret generic kong-session-config -n kong --from-file=admin_gui_session_conf

# Create Portal Config
cat << EOF > portal_gui_session_conf
{
    "cookie_name":"portal_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":true,
    "cookie_domain":".labs.konghq.com",
    "storage":"kong"
}
EOF
kubectl create secret generic kong-portal-session-config -n kong --from-file=portal_session_conf=portal_gui_session_conf

# Add Helm Repo
helm repo add kong https://charts.konghq.com
helm repo update

# Deploy Kong Control Plane
sed -i "s/admin_gui_url:.*/admin_gui_url: https:\/\/$KONG_MANAGER_URI/g" ./base/cp-values.yaml
sed -i "s/admin_api_url:.*/admin_api_url: https:\/\/$KONG_ADMIN_API_URI/g" ./base/cp-values.yaml
sed -i "s/admin_api_uri:.*/admin_api_uri: $KONG_ADMIN_API_URI/g" ./base/cp-values.yaml
sed -i "s/proxy_url:.*/proxy_url: https:\/\/$KONG_PROXY_URI/g" ./base/cp-values.yaml
sed -i "s/portal_api_url:.*/portal_api_url: https:\/\/$KONG_PORTAL_API_URI/g" ./base/cp-values.yaml
sed -i "s/portal_gui_host:.*/portal_gui_host: $KONG_PORTAL_GUI_HOST/g" ./base/cp-values.yaml

kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kong

helm install -f ./base/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=${KONG_MANAGER_URI} \
--set portal.ingress.hostname=${KONG_PORTAL_GUI_HOST} \
--set admin.ingress.hostname=${KONG_ADMIN_API_URI} \
--set portalapi.ingress.hostname=${KONG_PORTAL_API_URI} 

# Wait for Kong CP Pod
while [[ -z $(kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) ]]; do
  echo "Waiting for kong control plane pod to exist..."
  sleep 1
done
WAIT_POD=`kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}'`
echo "Kong control plane pod exists and now waiting for it to come online..."
kubectl wait --for=condition=Ready --timeout=300s pod $WAIT_POD -n kong

# Deploy Kong Data Plane
kubectl create namespace kong-dp
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-dp
kubectl create secret generic kong-enterprise-license -n kong-dp --from-file=license=/etc/kong/license.json
helm install -f ./base/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=${KONG_PROXY_URI}

# Wait for Kong DP Pods
while [[ -z $(kubectl get pods --selector=app=kong-dp-kong -n kong-dp -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) ]]; do
  echo "Waiting for kong data plane pod to exist..."
  sleep 1
done
WAIT_POD=`kubectl get pods --selector=app=kong-dp-kong -n kong-dp -o jsonpath='{.items[*].metadata.name}'`
echo "Kong data plane pod exists and now waiting for it to come online..."
kubectl wait --for=condition=Ready --timeout=300s pod $WAIT_POD -n kong-dp

# Deploy some course components
kubectl apply -f ./base/httpbin.yaml
