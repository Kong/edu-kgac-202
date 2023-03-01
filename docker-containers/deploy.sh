#!/usr/bin/env bash
CURRENTDIR=$(pwd)

cd /home/labuser/edu-kgac-202/docker-containers
docker-compose up -d

cd $CURRENTDIR