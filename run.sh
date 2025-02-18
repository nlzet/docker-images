#!/usr/bin/env sh
set -euxo pipefail

# configuration defaults
PHP_VERSION=${PHP_VERSION:-8.3}
DOCKER_PREFIX=${DOCKER_PREFIX:-nlzet/php}
NODE_MAJOR=${NODE_MAJOR:-20}

prepare() {
  # configure defaults if not set
  FROM_IMAGE=${FROM_IMAGE:-php:${PHP_VERSION}-fpm}
  PHP_EXTENSIONS=${PHP_EXTENSIONS:-@composer amqp gd bcmath bz2 exif ffi gd gettext gmp igbinary imagick intl mcrypt mysqli opcache pcntl pdo_mysql pdo_pgsql redis sockets soap xdebug xsl zip}
  NODE_MAJOR=${NODE_MAJOR:-20}

  # parse PHP version number
  docker pull ${FROM_IMAGE} > /dev/null 2>&1
  TMP=$(docker run -i ${FROM_IMAGE} php -v)
  export PHP_VERSION_NUMBER=$(echo $TMP | cut -d " " -f2 | cut -d " " -f1)
  export PHP_VERSION_MAJOR=$(echo $PHP_VERSION_NUMBER | cut -d "." -f1)
  export PHP_VERSION_MINOR=$(echo $PHP_VERSION_NUMBER | cut -d "." -f2)
  export PHP_VERSION_RELEASE=$(echo $PHP_VERSION_NUMBER | cut -d "." -f3)

  # configure docker tags
  export DOCKER_TAG="${DOCKER_PREFIX}:${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}"

  # print configuration
  echo "=== BUILD CONFIGURATION === "
  echo " "
  echo "PHP_VERSION: ${PHP_VERSION} (${PHP_VERSION_MAJOR}.${PHP_VERSION_MINOR}.${PHP_VERSION_RELEASE})"
  echo "PHP_EXTENSIONS: ${PHP_EXTENSIONS}"
  echo "FROM_IMAGE: ${FROM_IMAGE}"
  echo "DOCKER_PREFIX: ${DOCKER_PREFIX}"
  echo "DOCKER_TAG: ${DOCKER_TAG}"
  echo "NODE_MAJOR: ${NODE_MAJOR}"
}

buildimage () {
  echo "#########"
  echo "> Building image: ${DOCKER_TAG}-$1"
  echo "#########"
  echo docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${FROM_IMAGE} --build-arg NODE_MAJOR=${NODE_MAJOR} --target $2 -t ${DOCKER_TAG}-$1 php/ $3
  docker build --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" --build-arg FROM_IMAGE=${FROM_IMAGE} --build-arg NODE_MAJOR=${NODE_MAJOR} --target $2 -t ${DOCKER_TAG}-$1 php/ $3
}

testcontainer () {
  echo "#########"
  echo "> Testing container: $1"
  echo "#########"

  docker exec -w /var/www/php/test/ -i $1 php ./vendor/bin/phpunit -c ./phpunit.xml.dist --testsuite test
}

testimage () {
  echo "#########"
  echo "> Testing: $1"
  echo "#########"

  docker run \
    -w /var/www/php/test/ \
    -v $(pwd)/:/var/www \
    -i \
    $1 \
    php ./vendor/bin/phpunit -c ./phpunit.xml.dist --testsuite test
}

testxdebugimage () {
  echo "#########"
  echo "> Testing Xdebug: $1"
  echo "#########"

  docker run \
    -w /var/www/php/test/ \
    -v $(pwd)/php/test/config/php.ini:/usr/local/etc/php/conf.d/zz-override.ini \
    -v ~/.composer:/home/www/.composer \
    -v $(pwd)/:/var/www \
    -e XDEBUG_MODE=coverage \
    -i \
    $1 \
    php -d "zend_extension=xdebug.so" ./vendor/bin/phpunit -c ./phpunit.xml.dist --coverage-html=coverage --testsuite test
}

squashimage () {
  echo "#########"
  echo "> Squashing image: $1"
  echo "#########"

  docker image ls $1 | tail -n 1
  docker save $1 | docker-squash -o squashed.tar -t $1
  tar --delete -f squashed.tar manifest.json && cat squashed.tar | docker load
  rm -f image.tar squashed.tar
  docker image ls $1 | tail -n 1
}

pushimage () {
  echo "#########"
  echo "> Pushing image: $1"
  echo "#########"
  docker image ls $1 | tail -n 1
  docker push $1
}

case $1 in
  info)
    prepare
    ;;

  build)
    prepare
    buildimage "$2" "$3" "${4:---pull}"
    ;;

  testcontainer)
    prepare
    testcontainer "$2"
    ;;

  test)
    prepare
    testimage "${DOCKER_TAG}-cli"
    ;;

  testxdebug)
    prepare
    testxdebugimage "${DOCKER_TAG}-cli"
    ;;

  push)
    prepare
    pushimage "${DOCKER_TAG}-$2"
    ;;

  squash)
    prepare
    squashimage "${DOCKER_TAG}-$2"
    ;;

  *)
    echo "#########"
    echo "> Error: unexpected run command"
    echo "#########"
    ;;
esac
