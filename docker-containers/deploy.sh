#!/usr/bin/env bash
CURRENTDIR=`pwd`

cd $HOME/edu-kgac-202/docker-containers
docker-compose up -d

cd $CURRENTDIR