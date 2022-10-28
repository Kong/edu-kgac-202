#!/usr/bin/env bash

# Task: Obtain docker certificates and clone course repo
# Lab Home
cd $HOME

# Pull docker certs
#./setup-docker.sh

# Clone repo
git clone https://github.com/Kong/edu-kgac-202.git
cd $HOME/edu-kgac-202
git checkout localhost

# Task: Create the Kind Cluster Config
# Update: Config already created in repo
cat ./base/kind-config.yaml

# Task: Deploy the Kind Cluster
kind create cluster --config ./base/kind-config.yaml
#mv $HOME/edu-kgac-202/.kube $HOME
export KUBECONFIG=$HOME/.kube/config
kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

# Task: Create and Stage the SSL Certificates to K8s
openssl rand -out .rnd
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./cluster.key -out ./cluster.crt \
  -days 1095 -subj "/CN=kong_clustering"
kubectl create namespace kong
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong

# Task: Stage Resources and Set Password
#kubectl create secret generic kong-enterprise-license -n kong --from-file=license=$KONG_LICENSE
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
kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kong

# Task: Stage Portal Config and Dataplane Certs & License
cat << EOF > portal_gui_session_conf
{
    "cookie_name":"portal_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":true,
    "cookie_domain":"localhost",
    "storage":"kong"
}
EOF
kubectl create secret generic kong-portal-session-config -n kong --from-file=portal_session_conf=portal_gui_session_conf
kubectl create namespace kong-dp
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-dp
#kubectl create secret generic kong-enterprise-license -n kong-dp --from-file=license=$KONG_LICENSE

# Task: Add Kong Helm Repo & Update, Add Values
helm repo add kong https://charts.konghq.com
helm repo update
sed -i "s/admin_gui_url:.*/admin_gui_url: https:\/\/$KONG_MANAGER_URI/g" ./base/cp-values.yaml
sed -i "s/admin_api_url:.*/admin_api_url: https:\/\/$KONG_ADMIN_API_URI/g" ./base/cp-values.yaml
sed -i "s/admin_api_uri:.*/admin_api_uri: $KONG_ADMIN_API_URI/g" ./base/cp-values.yaml
sed -i "s/proxy_url:.*/proxy_url: https:\/\/$KONG_PROXY_URI/g" ./base/cp-values.yaml
sed -i "s/portal_api_url:.*/portal_api_url: https:\/\/$KONG_PORTAL_API_URI/g" ./base/cp-values.yaml
sed -i "s/portal_gui_host:.*/portal_gui_host: $KONG_PORTAL_GUI_HOST/g" ./base/cp-values.yaml

# Task: Deploy Kong Control Plane with Environment Vars
helm install -f ./base/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=${KONG_MANAGER_URI} \
--set portal.ingress.hostname=${KONG_PORTAL_GUI_HOST} \
--set admin.ingress.hostname=${KONG_ADMIN_API_URI} \
--set portalapi.ingress.hostname=${KONG_PORTAL_API_URI}

# Task: Deploy Kong Data Plane with Vars and Monitor
helm install -f ./base/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=${KONG_PROXY_URI}

# Task: Enable the Developer Portal
http -f PATCH localhost:30001/workspaces/default \
  config.portal=true

# Task: Create a Developer Account
http POST $KONG_PORTAL_API_URI/default/register <<< '{"email":"myemail@example.com",
                                                      "password":"password",
                                                      "meta":"{\"full_name\":\"Dev E. Loper\"}"
                                                     }'

# Task: Approve the Developer
http PATCH "$KONG_ADMIN_API_URI/default/developers/myemail@example.com" <<< '{"status": 0}'

# Task: Add an API Spec to test
http --form POST localhost:30001/files \
  "path=specs/jokes.one.oas.yaml" \
  "contents=@./exercises/apispec/jokes1OAS.yaml"

# Task: Backup Gateway Config Lab
sed -i "s/KONG_ADMIN_API_URI/https:\/\/$KONG_ADMIN_API_URI/g" ./deck/deck.yaml
deck dump --config deck/deck.yaml --output-file deck/preupgrade.yaml

# Task: Modify Helm Chart Values
sed -i 's/tag: "2.2"/tag: "2.5"/g' ./base/cp-values.yaml
sed -i 's/tag: "2.7-alpine"/tag: "2.8.1.1-alpine"/g' ./base/dp-values.yaml 
sed -i 's/tag: "2.7-alpine"/tag: "2.8.1.1-alpine"/g' ./base/cp-values.yaml 

# Task: Upgrade Data Plane
helm upgrade -f ./base/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=$KONG_PROXY_URI

# Task: Upgrade Control Plane
helm upgrade -f ./base/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI 

# Task: Verify Upgraded Version
http get $KONG_ADMIN_API_URL | jq .version