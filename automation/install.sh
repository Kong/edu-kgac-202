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
EOF

kind create cluster --config kind-config.yaml
export KUBECONFIG=/home/labuser/.kube/config

# Create Keys and Certs, Namespace, and Load into K8s
cd /home/labuser/kong-course-gateway-ops-for-kubernetes
openssl rand -writerand .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
kubectl create namespace kong
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
sed -i "s/admin_gui_url:/admin_gui_url: https:\/\/$KONG_MANAGER_URI/g" ./helm/cp-values.yaml
sed -i "s/admin_api_url:/admin_api_url: https:\/\/$KONG_ADMIN_API_URI/g" ./helm/cp-values.yaml
sed -i "s/admin_api_uri:/admin_api_uri: $KONG_ADMIN_API_URI/g" ./helm/cp-values.yaml
sed -i "s/proxy_url:/proxy_url: https:\/\/$KONG_PROXY_URI/g" ./helm/cp-values.yaml
sed -i "s/portal_api_url:/portal_api_url: https:\/\/$KONG_PORTAL_API_URI/g" ./helm/cp-values.yaml
sed -i "s/portal_gui_host:/portal_gui_host: $KONG_PORTAL_GUI_HOST/g" ./helm/cp-values.yaml

kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kong

helm install -f ./helm/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=${KONG_MANAGER_URI} \
--set portal.ingress.hostname=${KONG_PORTAL_GUI_HOST} \
--set admin.ingress.hostname=${KONG_ADMIN_API_URI} \
--set portalapi.ingress.hostname=${KONG_PORTAL_API_URI}

# Update Deployment Environment Variables
# kubectl patch deployment kong-kong -n kong -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"proxy\",\"env\":[\
# {\"name\":\"KONG_ADMIN_API_URI\",\"value\":\"${KONG_ADMIN_API_URI}\"},\
# {\"name\":\"KONG_ADMIN_GUI_URL\",\"value\":\"${KONG_ADMIN_GUI_URL}\"},\
# {\"name\":\"KONG_PORTAL_GUI_HOST\",\"value\":\"${KONG_PORTAL_GUI_HOST}\"},\
# {\"name\":\"KONG_PORTAL_API_URL\",\"value\":\"${KONG_PORTAL_API_URL}\"}\
# ]}]}}}}"

# kubectl patch deployment kong-kong -n kong -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"proxy\",\"env\":[\
# {\"name\":\"KONG_SMTP_HOST\",\"value\":\"smtp-server\"},\
# {\"name\":\"KONG_SMTP_PORT\",\"value\":\"1025\"},\
# {\"name\":\"KONG_PORTAL_EMAIL_VERIFICATION\",\"value\":\"off\"},\
# {\"name\":\"KONG_PORTAL_EMAILS_FROM\",\"value\":\"kong@konghq.com\"},\
# {\"name\":\"KONG_PORTAL_EMAILS_REPLY_TO\",\"value\":\"noreply@konghq.com\"},\
# {\"name\":\"KONG_ADMIN_EMAILS_FROM\",\"value\":\"kong@konghq.com\"},\
# {\"name\":\"KONG_ADMIN_EMAILS_REPLY_TO\",\"value\":\"noreply@konghq.com\"},\
# {\"name\":\"KONG_SMTP_MOCK\",\"value\":\"off\"},\
# {\"name\":\"KONG_SMTP_ADMIN_EMAILS\",\"value\":\"noreply@konghq.com\"}\
# ]}]}}}}"

#       KONG_SMTP_HOST: smtp.gmail.com
#       KONG_SMTP_PORT: 587
#       KONG_SMTP_AUTH_TYPE: plain
#       KONG_SMTP_STARTTLS: "on"
#       KONG_SMTP_USERNAME: kongemailtest@gmail.com
#       KONG_SMTP_PASSWORD: jNzjktweewwYiQdpd2jymXV
#       KONG_SMTP_ADMIN_EMAILS: noreply@konghq.com

# kubectl patch deployment kong-kong -n kong -p "{\"spec\": { \"template\" : { \"spec\" : {\"containers\":[{\"name\":\"proxy\",\"env\": [\
# {\"name\": \"KONG_SMTP_MOCK\", \"value\": \"off\"},\
# {\"name\": \"KONG_SMTP_ADMIN_EMAILS\", \"value\": \"kong@labs.konghq.com\"},\
# {\"name\": \"KONG_SMTP_HOST\", \"value\": \"mail\"},\
# {\"name\": \"KONG_SMTP_PORT\", \"value\":\"587\"},\
# {\"name\":\"KONG_SMTP_DOMAIN\",\"value\":\"labs.konghq.com\"},\
# {\"name\":\"KONG_PORTAL_EMAIL_VERIFICATION\",\"value\":\"off\"},\
# {\"name\":\"KONG_PORTAL_EMAILS_FROM\",\"value\":\"kong@labs.konghq.com\"},\
# {\"name\":\"KONG_PORTAL_EMAILS_REPLY_TO\",\"value\":\"kong@labs.konghq.com\"},\
# {\"name\":\"KONG_ADMIN_EMAILS_FROM\",\"value\":\"kong@labs.konghq.com\"},\
# {\"name\":\"KONG_ADMIN_EMAILS_REPLY_TO\",\"value\":\"kong@labs.konghq.com\"}\
# ]}]}}}}"

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
helm install -f ./helm/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=${KONG_PROXY_URI}

# Wait for Kong DP Pods
while [[ -z $(kubectl get pods --selector=app=kong-dp-kong -n kong-dp -o jsonpath='{.items[*].metadata.name}' 2>/dev/null) ]]; do
  echo "Waiting for kong data plane pod to exist..."
  sleep 1
done
WAIT_POD=`kubectl get pods --selector=app=kong-dp-kong -n kong-dp -o jsonpath='{.items[*].metadata.name}'`
echo "Kong data plane pod exists and now waiting for it to come online..."
kubectl wait --for=condition=Ready --timeout=300s pod $WAIT_POD -n kong-dp

echo ""
echo "KONG MANAGER URL"
echo $KONG_MANAGER_URL