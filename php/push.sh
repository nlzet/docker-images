#!/usr/bin/env sh

. ./php/env.sh

pushimage () {
  echo "#########"
  echo "> Pushing image: $1"
  echo "#########"
  echo " "
  docker image ls $1 | tail -n 1
#  docker push $1
}

pushimage "${DOCKER_TAG}-cli"
#pushimage "${DOCKER_TAG_MINOR}-cli"
pushimage "${DOCKER_TAG}-fpm"
#pushimage "${DOCKER_TAG_MINOR}-fpm"
pushimage "${DOCKER_TAG}-ci"
#pushimage "${DOCKER_TAG_MINOR}-ci"
