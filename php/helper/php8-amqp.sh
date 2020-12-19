#!/usr/bin/env sh

PHP_MAJOR_VERSION=$(echo $PHP_VERSION | cut -d "." -f1)

# move and configure multistage build output
configure_amqp8 () {
  echo "> configuring php8 amqp build"
  echo "extension=amqp.so" > /usr/local/etc/php/conf.d/docker-php-ext-amqp.ini
  mv -v /usr/local/lib/php/extensions/no-debug-non-zts-20200930/amqp8.so /usr/local/lib/php/extensions/no-debug-non-zts-20200930/amqp.so
}

# remove multistage build output, will be installed with pecl for PHP < 8
skip_amqp8 () {
  echo "> skipping php8 amqp build for PHP $PHP_MAJOR_VERSION"
  rm -f /usr/local/lib/php/extensions/no-debug-non-zts-20200930/amqp8.so
}

if [ "$PHP_MAJOR_VERSION" -eq "8" ]; then
  configure_amqp8
else
  skip_amqp8
fi
