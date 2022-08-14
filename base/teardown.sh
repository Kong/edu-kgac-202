#!/usr/bin/env bash
export KUBECONFIG=$HOME/.kube/config

# Delete kind cluster
kind delete cluster --name kongcluster

# Bring down docker containers
cd ./docker-containers
docker-compose down
cd ../
