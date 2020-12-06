#!/usr/bin/env sh

. ./php/env.sh

echo "#########"
echo "> Testing: ${DOCKER_PREFIX}"
echo "#########"
echo " "

docker run \
  -v $(pwd)/php/test/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
  -v ~/.composer:/home/www/.composer \
  -v $(pwd)/php/test/:/var/www \
  -e XDEBUG_MODE=coverage \
  -i \
  ${DOCKER_PREFIX}-cli \
  php -d "zend_extension=xdebug.so" /var/www/vendor/bin/phpunit --coverage-html=coverage --testsuite test
