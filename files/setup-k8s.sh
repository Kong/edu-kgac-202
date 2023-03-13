#!/bin/bash
mkdir -p ~/.kube
curl -o ~/.kube/config http://${AVL_PAIRED_CONTAINER_INTERNAL_DOMAIN}:9000/kubeconfig 
