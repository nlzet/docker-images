#!/usr/bin/env bash

echo " "
echo "config:"
echo " "
echo "FROM_IMAGE: ${FROM_IMAGE}"
echo "DOCKER_PREFIX: ${DOCKER_PREFIX}"
echo "PHP_EXTENSIONS: ${PHP_EXTENSIONS}"
echo " "
echo "used test image:"
echo "${DOCKER_PREFIX}-ci"
echo " "

docker run \
  -v $(pwd)/php/test/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
  -v ~/.composer:/home/www/.composer \
  -v $(pwd)/php/test/:/var/www \
  -i \
  ${DOCKER_PREFIX}-ci \
  php /var/www/vendor/bin/phpunit --testsuite defaults

docker run \
  -v $(pwd)/php/test/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
  -v ~/.composer:/home/www/.composer \
  -v $(pwd)/php/test/:/var/www \
  -e XDEBUG_MODE=coverage \
  -i \
  ${DOCKER_PREFIX}-ci \
  php -d "zend_extension=xdebug.so" /var/www/vendor/bin/phpunit --coverage-html=coverage --testsuite xdebug
