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
echo "PHP_MINOR_VERSION: ${PHP_MINOR_VERSION}"
echo "DOCKER_TAG: ${DOCKER_TAG}"
echo "DOCKER_TAG_MINOR: ${DOCKER_TAG_MINOR}"
echo " "
echo "used test image:"
echo "${DOCKER_PREFIX}-cli"
echo " "

docker run \
  -v $(pwd)/php/test/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
  -v ~/.composer:/home/www/.composer \
  -v $(pwd)/php/test/:/var/www \
  -e XDEBUG_MODE=coverage \
  -i \
  ${DOCKER_PREFIX}-cli \
  php -d "zend_extension=xdebug.so" /var/www/vendor/bin/phpunit --coverage-html=coverage --testsuite test
