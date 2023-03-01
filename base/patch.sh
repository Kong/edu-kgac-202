#!/usr/bin/env bash
export KUBECONFIG=/home/ubuntu/.kube/config

yq -i '.ingressController.image.tag = "2.5"' ./base/cp-values.yaml
yq -i '.image.tag = "2.8.1.1-alpine"' ./base/dp-values.yaml 
yq -i '.image.tag = "2.8.1.1-alpine"' ./base/cp-values.yaml 

helm upgrade -f ./base/dp-values.yaml kong-dp kong/kong -n kong-dp \
--set proxy.ingress.hostname=$KONGHOSTNAME

helm upgrade -f ./base/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONGHOSTNAME \
--set portal.ingress.hostname=$KONGHOSTNAME \
--set admin.ingress.hostname=$KONGHOSTNAME \
--set portalapi.ingress.hostname=$KONGHOSTNAME 

watch "kubectl get pods -A"
