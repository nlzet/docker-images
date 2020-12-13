ARG FROM_IMAGE
ARG PHP_EXTENSIONS
ARG LOCALEGEN="en_US.UTF-8 UTF-8\nnl_NL.UTF-8 UTF-8"

FROM debian:buster-slim AS builder
ENV MHSENDMAIL_VERSION=0.2.0

# build extra image optim libraries
RUN \
  pkgVolatile='wget build-essential cmake gcc libc6-dev git-core make libfreetype6-dev libicu-dev libjpeg-dev libjpeg62-turbo-dev libpng-dev zlib1g-dev libxrender1 libssl-dev autoconf automake libtool pkgconf nasm xfonts-75dpi xfonts-base' && \
  pkgPersistent='fontconfig libxext6 libfontconfig1 ca-certificates openssl libjpeg62-turbo make' && \
  set -x && \
  apt-get update && apt-get install -y $pkgVolatile $pkgPersistent --no-install-recommends

# Mailhog sendmail helper
RUN \
  wget -qq -O /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v${MHSENDMAIL_VERSION}/mhsendmail_linux_amd64 && \
  chmod +x /usr/local/bin/mhsendmail && \
  which mhsendmail

RUN \
  apt update && apt install -y  && \
  mkdir -p /tmp/mozjpeg && cd /tmp/mozjpeg && wget -qq https://github.com/mozilla/mozjpeg/archive/v3.3.1.tar.gz && tar -xzf v3.3.1.tar.gz && SRC_DIR=$(ls -t1 -d mozjpeg-* | head -n1) && cd $SRC_DIR && autoreconf -fiv && cd .. && sh $SRC_DIR/configure && make install prefix=/usr/local libdir=/etc/mozjpeg/lib64 && \
  apt-get purge -y --auto-remove $pkgVolatile && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

FROM composer:latest AS composer
FROM $FROM_IMAGE as extensions
ARG PHP_EXTENSIONS
ARG LOCALEGEN

#ENV PKG_CLEANLIST="librabbitmq-dev"
ENV PKG_CLEANLIST="librabbitmq-dev libssh-dev libbz2-dev cmake libmpdec-dev libenchant-dev libffi-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libwebp-dev libgraphicsmagick1-dev libgmp-dev zlib1g-dev zlib1g-dev libgnutls28-dev libcurl4-gnutls-dev libevent-dev libicu-dev libmagickwand-dev libkrb5-dev libc-client-dev firebird-dev libib-util libicu-dev libldap2-dev libmaxminddb-dev libmcrypt-dev libmemcached-dev zlib1g-dev libsasl2-dev libicu-dev libsasl2-dev libsnappy-dev libmosquitto-dev freetds-dev libpcre3-dev unixodbc-dev libpq-dev libzstd-dev libxml2-dev libssh2-1-dev uuid-dev libxml2-dev libxslt-dev cmake gnutls-dev libzip-dev libbz2-dev zlib1g-dev libmbedtls-dev"

COPY --from=builder /usr/local/bin/jpegtran /usr/local/bin/jpegtran
COPY --from=builder /etc/mozjpeg/lib64 /etc/mozjpeg/lib64
COPY --from=builder /usr/local/bin/mhsendmail /usr/local/bin/mhsendmail
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/
RUN \
  savedAptMark="$(apt-mark showmanual)" && \
  echo ">> saved apt mark" && \
  echo ">> $savedAptMark" && \
  php -v && \
  chmod +x /usr/local/bin/install-php-extensions && sync && \
  install-php-extensions ${PHP_EXTENSIONS} && \
  rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
  mkdir -p /home/www/.composer && \
  chown -R 1000:1000 -R /home/www/ && \
  pkgPersistent='curl gifsicle imagemagick jpegoptim libfreetype6 libjpeg62-turbo libmagic1 libpng16-16 libssl1.1 libxrender1 libzstd1 make openssl optipng pngcrush pngquant wget wkhtmltox xfonts-75dpi xfonts-base xfonts-encodings' && \
  set -x && \
  apt-get update && \
  apt-get install -y wget && \
  wget -qq https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb && \
  (dpkg -i wkhtmltox_0.12.5-1.buster_amd64.deb 2>&1 || apt install -yf) && \
  apt-get install -y $pkgPersistent --no-install-recommends && \
  rm -f wkhtmltox_0.12.5-1.buster_amd64.deb && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
  ln -sf /usr/bin/jpegoptim /usr/local/bin/jpegoptim && \
  ln -sf /usr/bin/optipng /usr/local/bin/optipng && \
  ln -sf /usr/bin/gifsicle /usr/local/bin/gifsicle && \ 
  ln -sf /usr/bin/pngquant /usr/local/bin/pngquant && \
  apt-mark auto '.*' > /dev/null && \
  apt-mark manual $savedAptMark $pkgPersistent && \
  apt-get purge -y --auto-remove ${PKG_CLEANLIST} && \
  apt-get install -y $pkgPersistent --no-install-recommends && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
  which wkhtmltopdf

VOLUME /home/www/.composer

FROM extensions as stage1
ARG LOCALEGEN

RUN \
  echo "date.timezone=UTC" > /usr/local/etc/php/conf.d/00-default.ini && \
  echo "memory_limit=-1" > /usr/local/etc/php/php-cli.ini && \
  groupadd -g 1000 www &&  \
  useradd -u 1000 -g 1000 -ms /bin/bash www && \
  echo "alias ll='ls -la'" >> /home/www/.bashrc && \
  mkdir -p /var/www && \
  echo "LANG=\"en_US.UTF-8\"" > /etc/default/locale && \
  echo $LOCALEGEN >> /etc/locale.gen && \
  apt-get update && \
  apt-get install -y locales && \
  locale-gen && \
  apt-get purge -y --auto-remove locales && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
  # cleanup stage 1
  chown -R 1000:1000 /home/www/

ENV TERM xterm
VOLUME /var/www
WORKDIR /var/www

USER www
ENV TERM xterm

FROM stage1 as stage2
USER root

# node/yarn/apt
RUN \
  curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  # todo: sendmail msmtp
  apt-get install -y --no-install-recommends nodejs yarn && \
  echo "node: $(node --version)" && \
  echo "npm: $(npm --version)" && \
  echo "yarn: $(yarn --version)" && \
  # Allow extension enable for the user "www"
  chown www:www -R /usr/local/etc/php/conf.d/ && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
  mkdir /var/run/sshd

USER www
CMD ["/usr/local/sbin/php-fpm"]

FROM stage2 as stage3

USER root

RUN \
    pkgLib='chromium libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb' && \
    pkgDel='' && \
    set -x && \
    apt-get update && apt-get install -y $pkgLib --no-install-recommends && \
    apt-get purge -y --auto-remove $pkgDel && \
    rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

RUN \
  wget https://get.symfony.com/cli/installer -O - | bash && \
  mv ~/.symfony/bin/symfony /usr/local/bin/symfony && \
  /usr/local/bin/symfony server:ca:install && \
  cp -r /root/.symfony/ /home/www/ && \
  chown 1000:1000 -R /home/www/

USER www
ENV PATH="${PATH}:/home/www/.yarn/bin/"
RUN yarn global add @api-platform/client-generator && \
  yarn cache clean && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

CMD ["php", "-a"]
