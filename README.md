# Kong Course - Gateway Ops for Kubernetes
Scripts and configs for the Gateway Ops for Kubernetes Course

# Clone Repo and Deploy
```bash
git clone https://github.com/Kong/kong-course-gateway-ops-for-kubernetes.git
source ./kong-course-gateway-ops-for-kubernetes/base/reset-lab.sh
```

# Teardown
```bash
# Delete Kind Cluster
kind delete cluster --name avl

# Shutdown Keycloak
CURRENTDIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/docker-containers
docker-compose down
cd $CURRENTDIR
```