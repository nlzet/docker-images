#!/usr/bin/env sh

. ./php/env.sh

build () {
  echo "#########"
  echo "> Building image: ${DOCKER_TAG}-$1"
  echo "#########"
  echo " "

  docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${FROM_IMAGE} --target $2 -t ${DOCKER_TAG}-$1 -t ${DOCKER_TAG_MINOR}-$1 php/ $3
}

build "cli" "stage1" "--pull --no-cache"
build "fpm" "stage2" "--cache-from=${DOCKER_PREFIX}-cli"
build "ci" "stage3" "--cache-from=${DOCKER_PREFIX}-fpm"
