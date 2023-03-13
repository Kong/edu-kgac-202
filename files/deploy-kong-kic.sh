#!/bin/bash

export KONG_EE_VERSION=3.1.0.0-alpine
export KIC_VERSION=2.7.0

cd /home/ubuntu/edu-kgac-202
yq -i '.networking.apiServerAddress = env(KIND_HOST)' ./base/kind-config.yaml

kind create cluster --config ./base/kind-config.yaml
export KUBECONFIG=/home/ubuntu/.kube/config

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/calico.yaml
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

kubectl create namespace kong
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add kong https://charts.konghq.com
helm repo update


# Create Keys and Certs, Namespace, and Load into K8s
openssl rand -writerand .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong

# Load License
kubectl create secret generic kong-enterprise-license -n kong --from-file=license=/usr/local/kong/license.json

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

# Deploy Kong Control Plane
yq -i '.env.admin_gui_url = env(KONG_MANAGER_URL)' ./base/cp-values.yaml
yq -i '.env.admin_api_url = env(KONG_ADMIN_API_URL)' ./base/cp-values.yaml
yq -i '.env.admin_api_uri = env(KONG_ADMIN_API_URI)' ./base/cp-values.yaml
yq -i '.env.proxy_url = env(KONG_PROXY_URL)' ./base/cp-values.yaml
yq -i '.env.portal_api_url = env(KONG_PORTAL_API_URL)' ./base/cp-values.yaml
yq -i '.env.portal_gui_host = env(KONG_PORTAL_GUI_HOST)' ./base/cp-values.yaml

kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kong

helm install -f ./base/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=${KONGHOSTNAME} \
--set portal.ingress.hostname=${KONGHOSTNAME} \
--set admin.ingress.hostname=${KONGHOSTNAME} \
--set portalapi.ingress.hostname=${KONGHOSTNAME} 

# Wait for Kong CP Pod
while [[ -z $(kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) ]]; do
  echo "Waiting for kong control plane pod to exist..."
  sleep 1
done
WAIT_POD=$(kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}')
echo "Kong control plane pod exists and now waiting for it to come online..."
kubectl wait --for=condition=Ready --timeout=300s pod $WAIT_POD -n kong

# Deploy Kong Data Plane
kubectl create namespace kong-dp
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-dp
kubectl create secret generic kong-enterprise-license -n kong-dp --from-file=license=/usr/local/kong/license.json
helm install -f ./base/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=${KONGHOSTNAME}

# Wait for Kong DP Pods
while [[ -z $(kubectl get pods --selector=app=kong-dp-kong -n kong-dp -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) ]]; do
  echo "Waiting for kong data plane pod to exist..."
  sleep 1
done
# # Deploy some course components
# kubectl apply -f ./base/httpbin.yaml

# kubectl apply -f ./base/httpbin.yaml && kubectl apply -f ./base/httpbin-ingress.yaml 

# http get $KONG_PROXY_URL/httpbin

echo "The system is ready"