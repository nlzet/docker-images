ARG FROM_IMAGE
ARG PHP_EXTENSIONS
ARG LOCALEGEN="en_US.UTF-8 UTF-8\nnl_NL.UTF-8 UTF-8"

# FROM rust:1-stretch as rust-builder
# RUN \
#   mkdir -p /tmp/pngquant && \
#   cd /tmp/pngquant && \
#   git clone  --recursive https://github.com/kornelski/pngquant.git . && \
#   cargo build --release && \
#   mv /tmp/pngquant/target/release/ /opt/pngquant/

FROM debian:buster-slim AS debian-builder
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

# wkhtmltopdf
RUN \
  wget -qq https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb && \
  (dpkg -i wkhtmltox_0.12.5-1.buster_amd64.deb 2>&1 || apt install -yf) && \
  rm -f wkhtmltox_0.12.5-1.buster_amd64.deb && \
  which wkhtmltopdf && \
  which wkhtmltoimage

RUN \
    apt update && apt install -y  && \
    mkdir -p /tmp/mozjpeg && cd /tmp/mozjpeg && wget -qq https://github.com/mozilla/mozjpeg/archive/v3.3.1.tar.gz && tar -xzf v3.3.1.tar.gz && SRC_DIR=$(ls -t1 -d mozjpeg-* | head -n1) && cd $SRC_DIR && autoreconf -fiv && cd .. && sh $SRC_DIR/configure && make install prefix=/usr/local libdir=/etc/mozjpeg/lib64 && \
    apt-get purge -y --auto-remove $pkgVolatile && \
    rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

FROM composer:latest AS composer
FROM $FROM_IMAGE as extensions
ARG PHP_EXTENSIONS
ARG LOCALEGEN

ENV PKG_CLEANLIST="librabbitmq-dev libssh-dev libbz2-dev cmake libmpdec-dev libenchant-dev libffi-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libwebp-dev libgraphicsmagick1-dev libgmp-dev zlib1g-dev zlib1g-dev libgnutls28-dev libcurl4-gnutls-dev libevent-dev libicu-dev libmagickwand-dev libkrb5-dev libc-client-dev firebird-dev libib-util libicu-dev libldap2-dev libmaxminddb-dev libmcrypt-dev libmemcached-dev zlib1g-dev libsasl2-dev libicu-dev libsasl2-dev libsnappy-dev libmosquitto-dev freetds-dev libpcre3-dev unixodbc-dev libpq-dev libzstd-dev libxml2-dev libssh2-1-dev uuid-dev libxml2-dev libxslt-dev cmake gnutls-dev libzip-dev libbz2-dev zlib1g-dev libmbedtls-dev"

# COPY --from=rust-builder /opt/pngquant /opt/pngquant
# COPY --from=debian-builder /usr/local/bin/pngquant /usr/local/bin/pngquant
COPY --from=debian-builder /usr/local/bin/jpegtran /usr/local/bin/jpegtran
COPY --from=debian-builder /etc/mozjpeg/lib64 /etc/mozjpeg/lib64
COPY --from=debian-builder /usr/local/bin/mhsendmail /usr/local/bin/mhsendmail
COPY --from=debian-builder /usr/local/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf
COPY --from=debian-builder /usr/local/bin/wkhtmltoimage /usr/local/bin/wkhtmltoimage
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/
RUN \
  php -v && \
  chmod +x /usr/local/bin/install-php-extensions && sync && \
  echo install-php-extensions ${PHP_EXTENSIONS} && \
  install-php-extensions ${PHP_EXTENSIONS} && \
  # disable xdebug by default, only enable iwith ini config.
  rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
  mkdir -p /home/www/.composer && \
  chown -R 1000:1000 -R /home/www/

# lib deps
RUN \
    pkgPersistent='libfontconfig1 libxrender1 imagemagick libjpeg62-turbo gifsicle jpegoptim make optipng pngcrush fontconfig libfontenc1 libxext6 xfonts-75dpi xfonts-base xfonts-encodings xfonts-utils pngquant' && \
    set -x && \
    apt-get update && apt-get install -y $pkgPersistent --no-install-recommends && \
    rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
    mv /usr/bin/jpegoptim /usr/local/bin/jpegoptim && \
    mv /usr/bin/optipng /usr/local/bin/optipng && \
    mv /usr/bin/gifsicle /usr/local/bin/gifsicle && \ 
    mv /usr/bin/pngquant /usr/local/bin/pngquant && \   
    apt-get purge -y --auto-remove ${PKG_CLEANLIST} ${PHPIZE_DEPS} && \
    rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

VOLUME /home/www/.composer

FROM extensions as stage0
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
  apt-get install -y locales wget && \
  locale-gen && \
  apt-get purge -y --auto-remove locales && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

ENV TERM xterm
VOLUME /var/www
WORKDIR /var/www

USER www
ENV TERM xterm

FROM stage0 as stage1

USER root
ENV DEBIAN_FRONTEND noninteractive

# build extra image optim libraries
RUN \
    pkgPersistent='libfontconfig1 imagemagick libjpeg62-turbo gifsicle jpegoptim make optipng pngcrush fontconfig libfontenc1 libxext6 xfonts-75dpi xfonts-base xfonts-encodings xfonts-utils' && \
    set -x && \
    apt-get update && apt-get install -y $pkgPersistent --no-install-recommends && \
    echo "convert: $(convert --version)" && \
    rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
    # cleanup stage 1
    chown -R 1000:1000 /home/www/

USER www
FROM stage1 as stage2
USER root

# node/yarn/apt
RUN \
  curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  # todo: sendmail msmtp
  apt-get install -y --no-install-recommends xvfb nodejs yarn openssh-server && \
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
