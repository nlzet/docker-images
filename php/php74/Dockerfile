FROM composer:latest AS composer
FROM php:7.4-fpm as init-stage

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd xdebug intl dom xmlrpc xsl gettext mbstring gmp bcmath zip bz2 ftp iconv curl soap mysqli pdo pdo_mysql pdo_pgsql mongodb amqp imagick igbinary

RUN \
    mkdir -p /home/www/.composer && \
    chown -vR 1000:1000 /home/www/.composer

VOLUME /home/www/.composer

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

RUN \
  echo "date.timezone=UTC" > /usr/local/etc/php/conf.d/00-default.ini && \
  echo "memory_limit=-1" > /usr/local/etc/php/php-cli.ini && \
  groupadd -g 1000 www &&  \
  useradd -u 1000 -g 1000 -ms /bin/bash www && \
  echo "alias ll='ls -la'" >> /home/www/.bashrc && \
  mkdir -p /app && \
  echo "LANG=\"en_US.UTF-8\"" > /etc/default/locale && \
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
  echo "nl_NL.UTF-8 UTF-8" >> /etc/locale.gen && \
  apt-get update && \
  apt-get install -y locales && \
  locale-gen && \
  apt-get -y clean && \
  apt-get -y autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /tmp/pear /var/lib/cache/* /var/lib/log/* && \
  # disable xdebug by default, only enable in fpm by mounting ini file.
  rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini 

FROM init-stage as cli-stage

VOLUME /app
WORKDIR /var/www
ENV TERM xterm

USER www

FROM cli-stage as fpm-stage

USER root

ENV DEBIAN_FRONTEND noninteractive
ENV DSSIM_VERSION=2.9.7
ENV MOZJPEG_VERSION=3.3.1
ENV PNGQUANT_VERSION=2.7.2
ENV JPEGTRAN_VERSION=9c

RUN \
  curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -y git-core curl wget openssl unzip zip \
  telnet rsync ssh-client xvfb imagemagick optipng pngcrush \
  jpegoptim gifsicle sendmail msmtp golang-go \
  nodejs && \
  apt-get install -y --no-install-recommends yarn && \
  echo "node: $(node --version)" && \
  echo "npm: $(npm --version)" && \
  echo "yarn: $(yarn --version)"
  # echo "convert: $(convert --version)"

RUN \
  # Allow extension enable for the user "www"
  chown www:www -vR /usr/local/etc/php/conf.d/

# Download and install wkhtmltopdf
RUN \
  wget -qq 'https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz' && \
  tar -xf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz && \
  rm -f wkhtmltox-0.12.4_linux-generic-amd64.tar.xz && \
  ls -lah && \
  cd wkhtmltox/bin && \
  mv wkhtmltopdf /usr/local/bin/wkhtmltopdf && \
  mv wkhtmltoimage /usr/local/bin/wkhtmltoimage && \
  wkhtmltopdf --version && \
  wkhtmltoimage --version && \
  cd - && \
  rm -Rf wkhtmltox/

ENV TERM xterm

# # Image optim libraries
# # RUN \
# #   mkdir -p /tmp/pngout && cd /tmp/pngout && wget -qq -O pngout.tar.gz http://static.jonof.id.au/dl/kenutils/pngout-20150319-linux.tar.gz && tar -xzvf pngout.tar.gz && mv pngout-20150319-linux/x86_64/pngout /usr/local/bin/pngout && which pngout && rm -Rf /tmp/pngout && \
# #   # mkdir -p /tmp/dssim && cd /tmp/dssim && wget -qq -O dssim.zip https://github.com/kornelski/dssim/releases/download/${DSSIM_VERSION}/dssim-${DSSIM_VERSION}.zip && unzip dssim.zip && dpkg -i ./linux/dssim_${DSSIM_VERSION}_amd64.deb && which dssim && rm -Rf /tmp/dssim && \
# #   mkdir -p /tmp/mozjpeg && cd /tmp/mozjpeg && git clone --depth 1 https://github.com/mozilla/mozjpeg.git && cd mozjpeg && cmake -G"Unix Makefiles" && make && make install && ln -s /opt/mozjpeg/bin/cjpeg /usr/bin/cjpeg && which cjpeg && rm -rf /tmp/mozjpeg && \
# #   mkdir -p /tmp/pngquant && cd /tmp/pngquant && git clone -b ${PNGQUANT_VERSION} --depth 1 https://github.com/kornelski/pngquant.git . && make && make install && which pngquant && rm -rf /tmp/pngquant && \
# #   mkdir -p /tmp/jpegtran && cd /tmp/jpegtran && wget -qq -O jpegtran.tar.gz http://www.ijg.org/files/jpegsrc.v${JPEGTRAN_VERSION}.tar.gz && tar -xzvf jpegtran.tar.gz && cd /tmp/jpegtran/jpeg-${JPEGTRAN_VERSION}/ && ./configure && make && make test && make install && which jpegtran && rm -Rf /tmp/jpegtran

# # Mailhog sendmail helper
ENV PATH $PATH:/home/www/go/bin
ENV GOPATH /home/www/go
RUN go get github.com/mailhog/mhsendmail && \
  ln -s $(which mhsendmail) /usr/local/bin/mhsendmail && \
  which mhsendmail

RUN \
  chown -R 1000:1000 /home/www/
#   apt-get -y clean && \
#   # apt-get -y autoclean && \
#   DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y icu-devtools* libfreetype6-dev* libicu-dev* libjpeg62-turbo-dev* libpng-dev* \
#   libpng-tools* libpthread-stubs0-dev* libwebp-dev* libwebpdemux2* \
#   libwebpmux3* libx11-dev* libxau-dev* libxcb1-dev* libxdmcp-dev* libxml2-dev* \
#   libxpm-dev* libxslt1-dev* x11proto-core-dev* x11proto-dev* \
#   xorg-sgml-doctools* xtrans-dev* zlib1g-dev* && \
# 	docker-php-source delete && \
# 	rm -rf /tmp/pear /var/lib/apt/lists/* /tmp/src /tmp/* /var/tmp/* /tmp/pickle /tmp/pickle.tmp /var/lib/log/* /var/lib/cache/*

FROM fpm-stage as ci-stage

USER www

ENV PATH="${PATH}:/home/www/.yarn/bin/"
RUN yarn global bin
RUN yarn global add @quasar/cli @vue/cli cypress && \
  yarn cache clean && \
  cypress install

# # RUN \
# #   apt-get update --fix-missing && \
# #   apt-get install --no-install-recommends -y \
# #   automake libtool nasm cmake autoconf file g++ gcc \
# #   libc-dev make gnupg2 pkg-config bzip2 \
# #   git-core curl wget openssl unzip zip telnet rsync ssh-client  \
# #   bc locales apt-transport-https \
# #   libfreetype6-dev libjpeg62-turbo-dev libjpeg-dev libpng-dev libgd-dev \
# #   libmcrypt-dev libxslt1-dev libicu-dev \
# #   libffi-dev libcurl4-openssl-dev libpcre3-dev libreadline6-dev librecode-dev \
# #   libsqlite3-dev libssl-dev libssl1.1 libxml2-dev libxslt-dev libzip-dev \
# #   libgmp-dev libbz2-dev zlib1g-dev libssh2-1 libssh2-1-dev librabbitmq-dev \
# #   libz-dev libxrender-dev libmagickwand-dev xvfb imagemagick \
# #   optipng pngcrush jpegoptim gifsicle \
# #   sendmail msmtp \
# #   golang-go && \
# # ENV PATH=/usr/local/bin:${PATH}
# # ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
# # RUN ldconfig
