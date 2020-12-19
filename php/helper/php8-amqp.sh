#!/usr/bin/env sh

PHP_MAJOR_VERSION=$(echo $PHP_VERSION | cut -d "." -f1)

install_amqp8 () {
  echo "> installing php8 amqp source build"
  docker-php-source extract
  apt update && apt -y install --no-install-recommends git librabbitmq-dev \
  git clone --branch master --depth 1 https://github.com/php-amqp/php-amqp.git /usr/src/php/ext/amqp \
  cd /usr/src/php/ext/amqp && git submodule update --init \
  docker-php-ext-install amqp
  rm -rf /usr/src/php/ext/amqp /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/
}

skip_amqp8 () {
  echo "> skipping php8 amqp source build for PHP $PHP_MAJOR_VERSION"
}

if [ "$PHP_MAJOR_VERSION" -eq "8" ]; then
  install_amqp8
else
  skip_amqp8
fi
