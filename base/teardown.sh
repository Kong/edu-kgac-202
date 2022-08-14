#!/usr/bin/env bash
export KUBECONFIG=$HOME/.kube/config

# Delete kind cluster
kind delete cluster --name kongcluster

CURRENTDIR=`pwd`
cd ./docker-containers
docker-compose down
cd $CURRENTDIR