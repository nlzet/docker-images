#!/usr/bin/env sh
set -euxo pipefail

# configuration defaults
IMAGE_BASE=php:8.3-fpm
IMAGE_CLI=nlzet/php:8.3-cli
IMAGE_FPM=nlzet/php:8.3-fpm
IMAGE_CI=nlzet/php:8.3-ci
CONTAINER_BASE=base
CONTAINER_CLI=cli
CONTAINER_FPM=fpm
CONTAINER_CI=ci

CONTAINERS="${CONTAINER_BASE} ${CONTAINER_CLI} ${CONTAINER_FPM} ${CONTAINER_CI}"

start() {  
  numContainers=$(docker ps -a --filter "name=$1" | wc -l) > /dev/null
  if [ $numContainers -ge 2 ]; then 
    return
  fi
  
  echo "> Starting $1"
  imagevar=$(echo $1 | tr '[:lower:]' '[:upper:]')
  imagevar="IMAGE_$imagevar"
  imagename=$(eval echo \$$imagevar)
  
  docker run -w /var/www/php/test/ --name $1 -d $imagename bash
}

analyze() {
  echo "> Analyzing $1"
  docker exec -i $1 dpkg -l > ./debug/dpkg.$1.list
  docker exec --user root -i $1 du -s /* > ./debug/du.$1.list
#  docker exec --user root -i $1 tree -L 8 /var /usr > ./debug/tree.$1.list
}

mkdir -p ./debug
# docker rm --force ${CONTAINERS}
for c in ${CONTAINERS}; do
  start "$c"
  analyze "$c"
done
