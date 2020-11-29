#!/usr/bin/env sh

OUTPUT=$(docker run -i ${FROM_IMAGE} php -v)
PHP_MINOR_VERSION=$(echo $OUTPUT | cut -d " " -f2 | cut -d " " -f1 | cut -d "." -f3)
DOCKER_TAG="${DOCKER_PREFIX}"
DOCKER_TAG_MINOR="${DOCKER_PREFIX}.${PHP_MINOR_VERSION}"

echo " "
echo "config:"
echo " "
echo "FROM_IMAGE: ${FROM_IMAGE}"
echo "DOCKER_PREFIX: ${DOCKER_PREFIX}"
echo "PHP_EXTENSIONS: ${PHP_EXTENSIONS}"
echo " "
echo "docker tag prefixes:"
echo " "
echo "${DOCKER_TAG}"
echo "${DOCKER_TAG_MINOR}"
echo " "

docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${PHP_FROM} --target stage1 -t ${DOCKER_TAG}-cli -t ${DOCKER_TAG_MINOR}-cli php/ --pull
docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${PHP_FROM} --target stage2 -t ${DOCKER_TAG}-fpm -t ${DOCKER_TAG_MINOR}-fpm --cache-from=${DOCKER_PREFIX}-cli php/
docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${PHP_FROM} --target stage3 -t ${DOCKER_TAG}-ci -t ${DOCKER_TAG_MINOR}-ci --cache-from=${DOCKER_PREFIX}-fpm php/
