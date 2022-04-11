# Kong Course - Gateway Ops for Kubernetes
Scripts and configs for the Gateway Ops for Kubernetes Course

## Pull Kubeconfig
```bash
alias k=kubectl
./setup-k8s.sh
```

## Install Helm
```bash
curl -L -o helm-v3.8.1-linux-amd64.tar.gz https://get.helm.sh/helm-v3.8.1-linux-amd64.tar.gz
tar -xvf ./helm-v3.8.1-linux-amd64.tar.gz
export PATH=$PATH:$HOME/linux-amd64
```

## Clone Repo
```bash
git clone https://github.com/Kong/kong-course-gateway-ops-for-kubernetes.git
cd kong-course-gateway-ops-for-kubernetes
```

## Create Keys and Certs, Namespace, and Load into K8s
```bash
openssl rand -writerand .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
kubectl create namespace kong
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong
```

## Load License
```bash
kubectl create secret generic kong-enterprise-license -n kong --from-file=license=/etc/kong/license.json
```

## Create Manager Config
```bash
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
```

## Create Portal Config
```bash
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
```

## Add Helm Repo
```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

## Edit Helm Values If Needed
```bash
vi cp-values.yaml
```

## Deploy Kong Control Plane and Patch K8s Resources
```bash
# Deploy Kong Control Plane
helm install -f cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI

# Update Deployment Environment Variables
kubectl patch deployment kong-kong -n kong -p "{\"spec\": { \"template\" : { \"spec\" : {\"containers\":[{\"name\":\"proxy\",\"env\": [{ \"name\" : \"KONG_ADMIN_API_URI\", \"value\": \"$KONG_ADMIN_API_URI\" },{ \"name\" : \"KONG_PORTAL_GUI_HOST\", \"value\": \"$KONG_PORTAL_GUI_HOST\" },{ \"name\" : \"KONG_PORTAL_API_URL\", \"value\": \"https://$KONG_PORTAL_API_URI\" }]}]}}}}"

# Wait for Kong CP Pods
WAIT_POD=`kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}'`
kubectl wait --for=condition=Ready pod $WAIT_POD -n kong
```

## Edit Helm Values If Needed
```bash
vi dp-values.yaml
```

## Deploy Kong Data Plane
```bash
# Deploy Kong Data Plane
kubectl create namespace kong-dp
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-dp
kubectl create secret generic kong-enterprise-license -n kong-dp --from-file=license=/etc/kong/license.json
helm install -f dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=$KONG_PROXY_URI
```

## Remove Helm Releases
```bash
# Remove DP
helm uninstall kong-dp -n kong-dp
# Remove CP
helm uninstall kong -n kong
```