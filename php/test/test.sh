#!/bin/sh
docker run \
  -v $(pwd)/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
  -v ~/.composer:/home/www/.composer \
  -v $(pwd):/var/www \
  -it \
  ${DOCKER_PREFIX}-ci \
  php ./vendor/bin/phpunit --testsuite defaults

docker run \
  -v $(pwd)/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
  -v ~/.composer:/home/www/.composer \
  -v $(pwd):/var/www \
  -it \
  ${DOCKER_PREFIX}-ci \
  php -d "zend_extension=xdebug.so" ./vendor/bin/phpunit --testsuite xdebug
