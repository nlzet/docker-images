FROM composer:latest AS composer
FROM php:5.6-fpm

ENV DEBIAN_FRONTEND noninteractive
ENV XDEBUG_VERSION=2.5.5
ENV SSH2_VERSION=0.13
ENV MEMCACHED_VERSION=2.2.0
ENV APCU_VERSION=4.0.11
ENV APCU_BC_VERSION=stable
ENV DSSIM_VERSION=2.9.7
ENV MOZJPEG_VERSION=3.3.1
ENV PNGQUANT_VERSION=2.7.2
ENV JPEGTRAN_VERSION=9c

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
  apt-get update --fix-missing && \
  apt-get install --no-install-recommends -y \
  apt-transport-https \
  libmcrypt-dev \
  libmemcached-dev \
  libxslt1-dev \
  libffi-dev \
  openssl \
  bzip2 \
  libcurl4-openssl-dev \
  libpcre3-dev \
  libreadline6-dev \
  librecode-dev \
  libsqlite3-dev \
  libssl-dev \
  libssl1.1 \
  libmagickwand-dev \
  libxml2-dev \
  libicu-dev \
  libxslt-dev \
  gnupg2 \
  imagemagick \
  bc \
  gcc \
  g++ \
  git \
  zip \
  libzip-dev \
  locales \
  telnet \
  xvfb \
  wget \
  openssh-server \
  ssh-client \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libjpeg-dev \
  libpng-dev \
  libgd-dev \
  libgmp-dev \
  libbz2-dev \
  zlib1g-dev \
  libssh2-1 \
  libssh2-1-dev \
  librabbitmq-dev \
  build-essential \
  autoconf \
  automake \
  libtool \
  nasm \
  make \
  cmake \
  pkg-config \
  libz-dev \
  libxrender-dev \
  optipng \
  pngcrush \
  jpegoptim \
  gifsicle \
  systemd \
  ansible \
  msmtp \
  rsync \
  unzip \
  golang-go && \
  curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -y nodejs && \
  apt-get install -y --no-install-recommends yarn && \
  echo "node: $(node --version)" && \
  echo "npm: $(npm --version)" && \
  echo "yarn: $(yarn --version)" && \
  echo "convert: $(convert --version)" && \
  locale-gen && \
  rm -rf /var/lib/apt/lists/*

ENV PATH=/usr/local/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
RUN ldconfig

# PHP Configuration
RUN \
  # intl
  docker-php-ext-configure intl && \
  docker-php-ext-install intl && \
  # dom/xml/xsl
  docker-php-ext-install dom xmlrpc xsl && \
  # gd/exif
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
  docker-php-ext-install -j$(nproc) gd exif && \
  # database
  docker-php-ext-install mysql mysqli pdo pdo_mysql && \
  # string
  docker-php-ext-install gettext mbstring && \
  # math
  ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
  docker-php-ext-install gmp bcmath && \
  # compression
  docker-php-ext-install zip bz2 && \
  # ftp
  docker-php-ext-install ftp && \
  # ssh2
  pecl install ssh2-${SSH2_VERSION} && \
  docker-php-ext-enable ssh2 && \
  # amqp
  docker-php-ext-install sockets && \
  pecl install amqp && \
  docker-php-ext-enable amqp && \
  # imagick
  pecl install imagick && \
  docker-php-ext-enable imagick && \
  # other extensions
  docker-php-ext-install iconv curl soap && \
  pecl install xdebug-${XDEBUG_VERSION} && \
  pecl install memcached-${MEMCACHED_VERSION} && docker-php-ext-enable memcached && \
  pecl install apcu-${APCU_VERSION} apcu_bc-${APCU_BC_VERSION} && \
  docker-php-ext-enable --ini-name docker-php-ext-apcu.ini apcu && \
  docker-php-ext-install mcrypt && \
  # Allow extension enable for the user "www"
  chown www:www -vR /usr/local/etc/php/conf.d/

# Download and install wkhtmltopdf
RUN \
  wget -qq 'https://downloads.wkhtmltopdf.org/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz' && \
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

# Image optim libraries
RUN \
  mkdir -p /tmp/pngout && cd /tmp/pngout && wget -qq -O pngout.tar.gz http://static.jonof.id.au/dl/kenutils/pngout-20150319-linux.tar.gz && tar -xzvf pngout.tar.gz && mv pngout-20150319-linux/x86_64/pngout /usr/local/bin/pngout && which pngout && rm -Rf /tmp/pngout && \
  mkdir -p /tmp/dssim && cd /tmp/dssim && wget -qq -O dssim.zip https://github.com/kornelski/dssim/releases/download/${DSSIM_VERSION}/dssim-${DSSIM_VERSION}.zip && unzip dssim.zip && dpkg -i ./linux/dssim_${DSSIM_VERSION}_amd64.deb && which dssim && rm -Rf /tmp/dssim && \
  mkdir -p /tmp/mozjpeg && cd /tmp/mozjpeg && git clone --depth 1 https://github.com/mozilla/mozjpeg.git && cd mozjpeg && cmake -G"Unix Makefiles" && make && make install && ln -s /opt/mozjpeg/bin/cjpeg /usr/bin/cjpeg && which cjpeg && rm -rf /tmp/mozjpeg && \
  mkdir -p /tmp/pngquant && cd /tmp/pngquant && git clone -b ${PNGQUANT_VERSION} --depth 1 https://github.com/kornelski/pngquant.git . && make && make install && which pngquant && rm -rf /tmp/pngquant && \
  mkdir -p /tmp/jpegtran && cd /tmp/jpegtran && wget -qq -O jpegtran.tar.gz http://www.ijg.org/files/jpegsrc.v${JPEGTRAN_VERSION}.tar.gz && tar -xzvf jpegtran.tar.gz && cd /tmp/jpegtran/jpeg-${JPEGTRAN_VERSION}/ && ./configure && make && make test && make install && which jpegtran && rm -Rf /tmp/jpegtran

# Mailhog sendmail helper
ENV PATH $PATH:/home/www/go/bin
ENV GOPATH /home/www/go
RUN go get github.com/mailhog/mhsendmail && \
  ln -s $(which mhsendmail) /usr/local/bin/mhsendmail && \
  which mhsendmail

# Composer
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer && \
  mkdir -p /home/www/.composer && \
  chown 1000:1000 -R /home/www/.composer

# Cleanup
RUN apt-get -y clean && apt-get -y purge && rm -rf /var/lib/apt/lists/* && rm -Rf /tmp/pear

# ENV
VOLUME /app
WORKDIR /app
ENV TERM xterm

USER www
