#!/usr/bin/env sh

docker push ${DOCKER_PREFIX}-cli
docker push ${DOCKER_PREFIX}-fpm
docker push ${DOCKER_PREFIX}-ci
