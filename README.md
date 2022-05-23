# Kong Course - Gateway Ops for Kubernetes
Scripts and configs for the Gateway Ops for Kubernetes Course

# Automation
```bash
git clone https://github.com/Kong/kong-course-gateway-ops-for-kubernetes.git
cd kong-course-gateway-ops-for-kubernetes
```

## Install and Patch
```bash
source ./automation/install-and-patch.sh
```

## 

## Remove Helm Releases and Delete Namespaces
```bash
# Remove Kong Data Plane
helm uninstall kong-dp -n kong-dp

# Remove Kong Control Plane
helm uninstall kong -n kong

# Remove Namespaces
kubectl delete ns kong
kubectl delete ns kong-dp

# Delete kind cluster
kind delete cluster --name avl
```