#!/usr/bin/env sh

docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${PHP_FROM} --target stage1 -t ${DOCKER_PREFIX}-cli php/ --pull
docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${PHP_FROM} --target stage2 -t ${DOCKER_PREFIX}-fpm --cache-from=${DOCKER_PREFIX}-cli php/
docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${PHP_FROM} --target stage3 -t ${DOCKER_PREFIX}-ci --cache-from=${DOCKER_PREFIX}-fpm php/
