ARG PHP_VERSION
ARG PHP_EXTENSIONS
ARG FROM_IMAGE=${FROM_IMAGE:-php:${PHP_VERSION}-fpm}
ARG LOCALEGEN="en_US.UTF-8 UTF-8\nnl_NL.UTF-8 UTF-8\nnl_BE.UTF-8 UTF-8\nfr_FR.UTF-8 UTF-8\nde_DE.UTF-8 UTF-8"
ARG UID=1000
ARG GID=1000

FROM debian:buster-slim AS builder

# build extra image optim libraries
RUN \
  pkgVolatile='wget build-essential cmake gcc libc6-dev make libfreetype6-dev libicu-dev libjpeg-dev libjpeg62-turbo-dev libpng-dev zlib1g-dev libxrender1 libssl-dev autoconf automake libtool pkgconf nasm xfonts-75dpi xfonts-base' && \
  pkgPersistent='fontconfig libxext6 libfontconfig1 ca-certificates openssl libjpeg62-turbo make' && \
  set -x && \
  apt-get update && apt-get install -y $pkgVolatile $pkgPersistent --no-install-recommends && \
  wget -qq -O /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 && \
  chmod +x /usr/local/bin/mhsendmail && \
  mkdir -p /tmp/mozjpeg && cd /tmp/mozjpeg && wget -qq https://github.com/mozilla/mozjpeg/archive/v3.3.1.tar.gz && tar -xzf v3.3.1.tar.gz && SRC_DIR=$(ls -t1 -d mozjpeg-* | head -n1) && cd $SRC_DIR && autoreconf -fiv && cd .. && sh $SRC_DIR/configure && make install prefix=/usr/local libdir=/etc/mozjpeg/lib64 && \
  apt-get purge -y --auto-remove $pkgVolatile && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

FROM $FROM_IMAGE as extensions
ARG PHP_VERSION
ARG PHP_EXTENSIONS
ARG LOCALEGEN
ARG UID
ARG GID

COPY --from=builder /usr/local/bin/jpegtran /usr/local/bin/jpegtran
COPY --from=builder /etc/mozjpeg/lib64 /etc/mozjpeg/lib64
COPY --from=builder /usr/local/bin/mhsendmail /usr/local/bin/mhsendmail

ADD ./helper/php8-amqp.sh /tmp/php8-amqp.sh
ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/
RUN \
  php -v && \
  chmod +x /usr/local/bin/install-php-extensions && sync && \
  chmod +x /tmp/php8-amqp.sh && \
  eval $(/tmp/php8-amqp.sh env) && \
  install-php-extensions ${PHP_EXTENSIONS} && \
  rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
  savedAptMark="$(apt-mark showmanual)" && \
  pkgPersistent='curl git git-core gifsicle imagemagick jpegoptim less libfreetype6 libjpeg62-turbo libmagic1 libpng16-16 librabbitmq4 libssl1.1 libxrender1 libzstd1 make nano openssl optipng pngcrush pngquant ssh-client unzip vim wget wkhtmltox xfonts-75dpi xfonts-base xfonts-encodings' && \
  set -x && \
  apt-get update && \
  apt-get install -y wget && \
  wget -qq https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb && \
  (dpkg -i wkhtmltox_0.12.5-1.buster_amd64.deb 2>&1 || apt install -yf) && \
  apt-get install -y $pkgPersistent --no-install-recommends && \
  rm -f wkhtmltox_0.12.5-1.buster_amd64.deb && \
  ln -sf /usr/bin/jpegoptim /usr/local/bin/jpegoptim && \
  ln -sf /usr/bin/optipng /usr/local/bin/optipng && \
  ln -sf /usr/bin/gifsicle /usr/local/bin/gifsicle && \ 
  ln -sf /usr/bin/pngquant /usr/local/bin/pngquant && \
  apt-mark auto '.*' > /dev/null && \
  apt-mark manual $savedAptMark $pkgPersistent && \
  apt-get purge -y --auto-remove && \
  apt-get install -y $pkgPersistent --no-install-recommends && \
  /tmp/php8-amqp.sh build && \
  unset INSTALL_AMQP8 && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

FROM extensions as stage1
ARG PHP_VERSION
ARG PHP_EXTENSIONS
ARG LOCALEGEN
ARG UID
ARG GID

RUN \
  echo "date.timezone=UTC" > /usr/local/etc/php/conf.d/00-default.ini && \
  echo "memory_limit=-1" > /usr/local/etc/php/php-cli.ini && \
  groupadd -g $UID www &&  \
  useradd -u $UID -g $GID -ms /bin/bash www && \
  echo "alias ll='ls -la'" >> /home/www/.bashrc && \
  echo "LANG=\"en_US.UTF-8\"" > /etc/default/locale && \
  echo $LOCALEGEN >> /etc/locale.gen && \
  apt-get update && \
  # installation of locales will trigger locale-gen.
  apt-get install -y --no-install-recommends locales && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
  mkdir -p /home/www/.composer/cache/ && \
  mkdir -p /home/www/.ssh/ && \
  mkdir -p /var/www && \
  chown -vR $UID:$GID /home/www/ && \
  chown -vR $UID:$GID /var/www/

VOLUME /home/www/.composer
VOLUME /home/www/.ssh
VOLUME /var/www

ENV TERM xterm
WORKDIR /var/www

USER www
ENV TERM xterm

FROM stage1 as stage2
ARG PHP_VERSION
ARG PHP_EXTENSIONS
ARG LOCALEGEN
ARG UID
ARG GID

USER root
RUN \
  curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  # todo: sendmail msmtp
  apt-get install -y --no-install-recommends nodejs yarn && \
  # Allow extension enable for the user "www"
  chown -R $UID:$GID /usr/local/etc/php/conf.d/ && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
  mkdir /var/run/sshd

USER www
CMD ["/usr/local/sbin/php-fpm"]

FROM stage2 as stage3
ARG PHP_VERSION
ARG PHP_EXTENSIONS
ARG LOCALEGEN
ARG UID
ARG GID

USER root
RUN \
    pkgLib='ansible chromium libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb' && \
    pkgDel='' && \
    set -x && \
    apt-get update && apt-get install -y $pkgLib --no-install-recommends && \
    apt-get purge -y --auto-remove $pkgDel && \
    rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
    wget https://get.symfony.com/cli/installer -O - | bash && \
    mv ~/.symfony/bin/symfony /usr/local/bin/symfony && \
    /usr/local/bin/symfony server:ca:install && \
    cp -r /root/.symfony/ /home/www/ && \
    chown -R $UID:$GID /home/www/

USER www
ENV PATH="${PATH}:/home/www/.yarn/bin/"
RUN yarn global add @api-platform/client-generator && \
  yarn cache clean && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

CMD ["php", "-a"]
