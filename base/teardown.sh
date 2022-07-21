#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config

# Delete kind cluster
kind delete cluster --name avl

CURRENTDIR=`pwd`
cd /home/labuser/kong-course-gateway-ops-for-kubernetes/docker-containers
docker-compose down
cd $CURRENTDIR