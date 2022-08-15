# Kong Course - Gateway Ops for Kubernetes
Scripts and configs for the Gateway Ops for Kubernetes Course

# Requirements
This branch assumes the following commands and tools are installed:
1. kind
2. kubectl
3. openssl
4. docker
5. helm
6. $KONG_LICENSE needs to be set to the local path of your kong license json file

# Clone Repo and Deploy
```bash
git clone https://github.com/Kong/kong-course-gateway-ops-for-kubernetes.git
cd ./kong-course-gateway-ops-for-kubernetes
git checkout localhost
source ./base/reset-lab.sh
```

# Teardown
```bash
# Delete Kind Cluster
kind delete cluster --name kongcluster

# Shutdown Keycloak
CURRENTDIR=`pwd`
cd $HOME/kong-course-gateway-ops-for-kubernetes/docker-containers
docker-compose down
cd $CURRENTDIR
```