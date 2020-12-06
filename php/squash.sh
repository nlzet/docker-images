#!/usr/bin/env sh

. ./php/env.sh

squash () {
  echo "#########"
  echo "> Squashing image: $1"
  echo "#########"
  echo " "

  docker image ls $1 | tail -n 1
  docker save $1 | docker-squash -o squashed.tar -t $1
  tar --delete -f squashed.tar manifest.json && cat squashed.tar | docker load
  rm -f image.tar squashed.tar
  docker image ls $1 | tail -n 1
  echo " "
}

squash "${DOCKER_TAG}-minimal" "${DOCKER_TAG_MINOR}-minimal"
squash "${DOCKER_TAG}-cli" "${DOCKER_TAG_MINOR}-cli"
squash "${DOCKER_TAG}-fpm" "${DOCKER_TAG_MINOR}-fpm"
squash "${DOCKER_TAG}-ci" "${DOCKER_TAG_MINOR}-ci"
