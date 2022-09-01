# Kong Course - Gateway Ops for Kubernetes
Scripts and configs for the Gateway Ops for Kubernetes Course

# Clone Repo and Deploy
```bash
git clone https://github.com/Kong/edu-kgac-202.git
source ./edu-kgac-202/base/reset-lab.sh
```

# Teardown
```bash
# Delete Kind Cluster
kind delete cluster --name avl

# Shutdown Keycloak
CURRENTDIR=`pwd`
cd /home/labuser/edu-kgac-202/docker-containers
docker-compose down
cd $CURRENTDIR
```