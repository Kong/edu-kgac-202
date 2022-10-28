#!/usr/bin/env bash

# Create Kind Cluster
kind create cluster --config ./base/kind-config.yaml
export KUBECONFIG=$HOME/.kube/config
#kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/calico.yaml
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

# K8s resources, prometheus, grafana, and statsd
kubectl create namespace monitoring
kubectl create namespace kong
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install -f ./exercises/monitoring/prometheus-values.yaml prometheus prometheus-community/kube-prometheus-stack -n monitoring --wait
helm install -f ./exercises/monitoring/statsd-values.yaml statsd prometheus-community/prometheus-statsd-exporter -n monitoring --wait
helm install redis bitnami/redis -n kong --set auth.enabled=false --set replica.replicaCount=0

# Create Keys and Certs, Namespace, and Load into K8s
openssl rand -out .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong

# Load License
#kubectl create secret generic kong-enterprise-license -n kong --from-file=license=$KONG_LICENSE

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
    "cookie_secure":false,
    "cookie_domain":"localhost",
    "storage":"kong"
}
EOF
kubectl create secret generic kong-portal-session-config -n kong --from-file=portal_session_conf=portal_gui_session_conf

# Add Kong Helm Repo
helm repo add kong https://charts.konghq.com
helm repo update

# Deploy Kong Control Plane
kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kong

helm install -f ./base/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=localhost \
--set admin.ingress.hostname=localhost \
--set portalapi.ingress.hostname=localhost 

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
#kubectl create secret generic kong-enterprise-license -n kong-dp --from-file=license=$KONG_LICENSE
helm install -f ./base/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=localhost

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
