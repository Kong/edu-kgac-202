  
#!/bin/bash
# stops script on first error
# set -e

###########################################################################
# DEPLOY KONG FOR KUBERNETES
############################################################################

export KONG_EE_VERSION=3.1.0.0-alpine
export KIC_VERSION=2.7.0

kubectl create namespace kong
kubectl create secret generic kong-enterprise-license --from-file=license=/etc/kong/license.json -n kong
kubectl apply -f kong-ingress-enterprise.yaml
kubectl patch service kong-proxy --namespace=kong --type='json' --patch='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":31112}]'
echo "Waiting for Kong to Deploy..."

kubectl wait \
  --for=condition=available \
  --timeout=120s \
  --namespace=kong \
  deployment/ingress-kong

echo "Kong Deployed"