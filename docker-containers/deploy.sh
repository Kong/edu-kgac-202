#!/usr/bin/env bash
CURRENTDIR=`pwd`

cd /home/labuser/kong-course-gateway-ops-for-kubernetes/docker-containers
docker-compose up -d

cd $CURRENTDIR