#!/usr/bin/env bash
export KUBECONFIG=/home/labuser/.kube/config

# Delete kind cluster
kind delete cluster --name multiverse

CURRENTDIR=`pwd`
cd /home/labuser/edu-kgac-202/docker-containers
docker-compose down
cd $CURRENTDIR