#!/usr/bin/env sh

OUTPUT=$(docker run -i ${FROM_IMAGE} php -v)
export PHP_MINOR_VERSION=$(echo $OUTPUT | cut -d " " -f2 | cut -d " " -f1 | cut -d "." -f3)
export DOCKER_TAG="${DOCKER_PREFIX}"
export DOCKER_TAG_MINOR="${DOCKER_PREFIX}.${PHP_MINOR_VERSION}"

echo " "
echo "config:"
echo " "
echo "FROM_IMAGE: ${FROM_IMAGE}"
echo "DOCKER_PREFIX: ${DOCKER_PREFIX}"
echo "PHP_EXTENSIONS: ${PHP_EXTENSIONS}"
echo "PHP_MINOR_VERSION: ${PHP_MINOR_VERSION}"
echo "DOCKER_TAG: ${DOCKER_TAG}"
echo "DOCKER_TAG_MINOR: ${DOCKER_TAG_MINOR}"
echo " "
