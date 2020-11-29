#!/bin/bash
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo $DIR

docker run \
  -v ${DIR}/test/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
  -v ~/.composer:/home/www/.composer \
  -v ${DIR}/test/:/var/www \
  -i \
  ${DOCKER_PREFIX}-ci \
  php /var/www/vendor/bin/phpunit --testsuite defaults

docker run \
  -v ${DIR}/test/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
  -v ~/.composer:/home/www/.composer \
  -v ${DIR}/test/:/var/www \
  -e XDEBUG_MODE=coverage \
  -i \
  ${DOCKER_PREFIX}-ci \
  php -d "zend_extension=xdebug.so" /var/www/vendor/bin/phpunit --coverage-html=coverage --testsuite xdebug
