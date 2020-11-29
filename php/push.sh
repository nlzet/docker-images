#!/usr/bin/env sh

OUTPUT=$(docker run -i ${FROM_IMAGE} php -v)
echo $OUTPUT
PHP_MINOR_VERSION=$(echo $OUTPUT | grep -Po -i "^PHP (\d\.\d\.\d+)" | cut -d " " -f2 | cut -d "." -f3)

DOCKER_TAG="${DOCKER_PREFIX}"
DOCKER_TAG_MINOR="${DOCKER_PREFIX}.${PHP_MINOR_VERSION}"

echo " "
echo "docker tag prefixes:"
echo "${DOCKER_TAG}"
echo "${DOCKER_TAG_MINOR}"
echo " "

docker push ${DOCKER_TAG}-cli
#docker push ${DOCKER_TAG_MINOR}-cli
docker push ${DOCKER_TAG}-fpm
#docker push ${DOCKER_TAG_MINOR}-fpm
docker push ${DOCKER_TAG}-ci
#docker push ${DOCKER_TAG_MINOR}-ci
