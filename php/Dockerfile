ARG PHP_VERSION
ARG PHP_EXTENSIONS
ARG FROM_IMAGE=${FROM_IMAGE:-php:${PHP_VERSION}-fpm}
ARG LOCALEGEN="en_US.UTF-8 UTF-8\nnl_NL.UTF-8 UTF-8\nnl_BE.UTF-8 UTF-8\nfr_FR.UTF-8 UTF-8\nde_DE.UTF-8 UTF-8"
ARG UID=1000
ARG GID=1000

FROM debian:buster-slim AS builder

# build extra image optim libraries
RUN \
  pkgVolatile='autoconf automake build-essential cmake gcc git libc6-dev libfreetype6-dev libicu-dev libjpeg-dev libjpeg62-turbo-dev libpng-dev libssl-dev libtool libxrender1 make nasm pkgconf texinfo wget xfonts-75dpi xfonts-base zlib1g-dev' && \
  pkgPersistent='fontconfig libxext6 libfontconfig1 ca-certificates openssl libjpeg62-turbo make' && \
  set -x && \
  apt-get update && apt-get install -y $pkgVolatile $pkgPersistent --no-install-recommends

RUN \
  wget -qq -O /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 && \
  chmod +x /usr/local/bin/mhsendmail && \
  mkdir -p /tmp/mozjpeg && git clone --quiet --depth=1 https://github.com/mozilla/mozjpeg.git /tmp/mozjpeg && mkdir -p /tmp/mozjpeg/build && cd /tmp/mozjpeg/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local/ -DENABLE_STATIC=1 -DENABLE_SHARED=0 .. && make && make install && cd / && \
  mkdir -p /tmp/webp && cd /tmp/webp && wget -qq -O libwebp.tar.gz https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.2.2-rc2-linux-x86-64.tar.gz && gunzip -c libwebp.tar.gz | tar x --strip-components=1 && cp -v /tmp/webp/bin/* /usr/local/bin/ && cd / && rm -rf /tmp/webp && \
  apt-get purge -y --auto-remove $pkgVolatile && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

FROM $FROM_IMAGE as extensions
ARG PHP_VERSION
ARG PHP_EXTENSIONS
ARG LOCALEGEN
ARG UID
ARG GID

COPY --from=builder /usr/local/bin/jpegtran /usr/local/bin/jpegtran
#COPY --from=builder /etc/mozjpeg/lib64 /etc/mozjpeg/lib64
COPY --from=builder /usr/local/bin/mhsendmail /usr/local/bin/mhsendmail
COPY --from=builder /usr/local/bin/anim_diff /usr/local/bin/anim_diff
COPY --from=builder /usr/local/bin/anim_dump /usr/local/bin/anim_dump
COPY --from=builder /usr/local/bin/cwebp /usr/local/bin/cwebp
COPY --from=builder /usr/local/bin/dwebp /usr/local/bin/dwebp
COPY --from=builder /usr/local/bin/get_disto /usr/local/bin/get_disto
COPY --from=builder /usr/local/bin/gif2webp /usr/local/bin/gif2webp
COPY --from=builder /usr/local/bin/img2webp /usr/local/bin/img2webp
COPY --from=builder /usr/local/bin/vwebp /usr/local/bin/vwebp
COPY --from=builder /usr/local/bin/webpinfo /usr/local/bin/webpinfo
COPY --from=builder /usr/local/bin/webpmux /usr/local/bin/webpmux
COPY --from=builder /usr/local/bin/webp_quality /usr/local/bin/webp_quality

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN \
  php -v && \
  chmod +x /usr/local/bin/install-php-extensions && sync && \
  install-php-extensions ${PHP_EXTENSIONS} && \
  rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
  savedAptMark="$(apt-mark showmanual)" && \
  pkgPersistent='curl git git-core gifsicle imagemagick jpegoptim less libfreetype6 libjpeg62-turbo libmagic1 libpng16-16 librabbitmq4 libssl1.1 libxrender1 libzstd1 make nano openssl optipng pngcrush pngquant rsync ssh-client unzip vim wget wkhtmltox xfonts-75dpi xfonts-base xfonts-encodings' && \
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
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

# php/composer version alias
RUN \
  export tmp_php_version=$(echo $PHP_VERSION | cut -d "." -f1-2 | sed 's/\.//g') && \
  echo "-> alias version: ${tmp_php_version}" && \
  ln -sf /usr/local/bin/php /usr/local/bin/php${tmp_php_version} && \
  ln -sf /usr/local/bin/composer /usr/local/bin/composer${tmp_php_version} && \
  echo "> php alias version: " && \
  $(echo php$tmp_php_version --version) && \
  echo "> composer alias version: " && \
  $(echo composer$tmp_php_version --version) && \
  export tmp_php_version=

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
  curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
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
    pkgLib='ansible chromium firefox-esr libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 python python-setuptools software-properties-common sudo xauth xvfb' && \
    pkgDel='' && \
    set -x && \
    apt-get update && apt-get install -y $pkgLib --no-install-recommends && \
    apt-get purge -y --auto-remove $pkgDel && \
    rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
    wget https://get.symfony.com/cli/installer -O - | bash && \
    mv ~/.symfony5/bin/symfony /usr/local/bin/symfony && \
    /usr/local/bin/symfony server:ca:install && \
    cp -r /root/.symfony5/ /home/www/ && \
    chown -R $UID:$GID /home/www/ && \
    wget -O /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
    chmod +x /usr/local/bin/wait-for-it

USER www
ENV PATH="${PATH}:/home/www/.yarn/bin/"
RUN yarn global add @api-platform/client-generator @quasar/cli cypress && \
  yarn cache clean && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

CMD ["php", "-a"]
USER root
