ARG FROM_IMAGE
FROM composer:latest AS composer
FROM $FROM_IMAGE as init-stage

ARG PHP_EXTENSIONS

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    echo install-php-extensions ${PHP_EXTENSIONS} && \
    install-php-extensions ${PHP_EXTENSIONS} && \
    # disable xdebug by default, only enable in fpm by mounting ini file.
    rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    mkdir -p /home/www/.composer && \
    chown -R 1000:1000 -R /home/www/

VOLUME /home/www/.composer

COPY --from=composer /usr/bin/composer /usr/local/bin/composer

RUN \
  chmod +x /usr/local/bin/composer && \
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
  apt-get install -y tree locales git-core curl wget openssl unzip telnet rsync ssh-client zip && \
  locale-gen && \
  apt-get -y clean && \
  apt-get -y autoclean && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/ && \
  tree -L 8 / > /tmp/stage0.txt

ENV TERM xterm
VOLUME /app
WORKDIR /var/www

FROM init-stage as stage1

USER www
ENV TERM xterm

RUN tree -L 8 / > /tmp/stage1.txt

FROM stage1 as stage2

ENV PATH $PATH:/home/www/go/bin
ENV GOPATH /home/www/go

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
  apt-get install -y --no-install-recommends xvfb sendmail msmtp golang-go nodejs yarn \
  libfontconfig1 libxrender1 \
  optipng pngcrush jpegoptim gifsicle && \
  echo "node: $(node --version)" && \
  echo "npm: $(npm --version)" && \
  echo "yarn: $(yarn --version)" && \
  # echo "convert: $(convert --version)" && \
  # Allow extension enable for the user "www"
  chown www:www -R /usr/local/etc/php/conf.d/ && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

# Image optim libraries
RUN \
    buildDeps='gcc libc6-dev make cmake bison' && \
    pkgExtra='libfreetype6-dev libpng-dev zlib1g-dev libicu-dev libjpeg62-turbo-dev libjpeg-dev libjpeg62-turbo libssl-dev build-essential' && \
    set -x && \
    apt-get update && apt-get install -y $buildDeps $pkgExtra --no-install-recommends && \
    mkdir -p /tmp/pngout && cd /tmp/pngout && wget -qq -O pngout.tar.gz http://static.jonof.id.au/dl/kenutils/pngout-20150319-linux.tar.gz && tar -xzvf pngout.tar.gz && mv pngout-20150319-linux/x86_64/pngout /usr/local/bin/pngout && which pngout && rm -Rf /tmp/pngout && \
    mkdir -p /tmp/dssim && cd /tmp/dssim && wget -qq -O dssim.zip https://github.com/kornelski/dssim/releases/download/${DSSIM_VERSION}/dssim-${DSSIM_VERSION}.zip && unzip dssim.zip && dpkg -i ./linux/dssim_${DSSIM_VERSION}_amd64.deb && which dssim && rm -Rf /tmp/dssim && \
    mkdir -p /tmp/mozjpeg && cd /tmp/mozjpeg && git clone --depth 1 https://github.com/mozilla/mozjpeg.git && cd mozjpeg && cmake -G"Unix Makefiles" && make && make install && rm -rf /tmp/mozjpeg && \
    mkdir -p /tmp/pngquant && cd /tmp/pngquant && git clone -b ${PNGQUANT_VERSION} --depth 1 https://github.com/kornelski/pngquant.git . && make && make install && which pngquant && rm -rf /tmp/pngquant && \
    mkdir -p /tmp/jpegtran && cd /tmp/jpegtran && wget -qq -O jpegtran.tar.gz http://www.ijg.org/files/jpegsrc.v${JPEGTRAN_VERSION}.tar.gz && tar -xzvf jpegtran.tar.gz && cd /tmp/jpegtran/jpeg-${JPEGTRAN_VERSION}/ && ./configure && make && make test && make install && which jpegtran && rm -Rf /tmp/jpegtran && \
    cd /root && \
    apt-get purge -y --auto-remove $buildDeps && \
    rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

# Mailhog sendmail helper
RUN \
    go get github.com/mailhog/mhsendmail && \
    ln -sf $(which mhsendmail) /usr/local/bin/mhsendmail && \
    which mhsendmail && \
    chown -R 1000:1000 /home/www/

# wkhtmltopdf
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

CMD ["/usr/local/sbin/php-fpm"]

RUN tree -L 8 / > /tmp/stage2.txt

FROM stage2 as stage3

RUN \
  wget https://get.symfony.com/cli/installer -O - | bash && \
  mv ~/.symfony/bin/symfony /usr/local/bin/symfony && \
  /usr/local/bin/symfony server:ca:install && \
  cp -r /root/.symfony/ /home/www/ && \
  chown 1000:1000 -R /home/www/

USER www
ENV PATH="${PATH}:/home/www/.yarn/bin/"
RUN yarn global add @quasar/cli @vue/cli cypress @api-platform/client-generator && \
  yarn cache clean && \
  rm -rf /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/

CMD ["php", "-a"]

RUN tree -L 8 / > /tmp/stage3.txt
