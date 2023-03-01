#!/usr/bin/env bash
CURRENTDIR=$(pwd)

cd /home/ubuntu/edu-kgac-202/docker-containers
docker-compose down

cd $CURRENTDIR