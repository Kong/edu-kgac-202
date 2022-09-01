#!/usr/bin/env bash
CURRENTDIR=`pwd`

cd /home/labuser/edu-kgac-201/docker-containers
docker-compose down

cd $CURRENTDIR