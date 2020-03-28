FROM nlzet/php73-cli

USER root
RUN \
    wget https://get.symfony.com/cli/installer -O - | bash && \
    cp ~/.symfony/bin/symfony /usr/local/bin/symfony && \
    chmod +x /usr/local/bin/symfony && \
    apt-get -y -qq update && \
    apt-get -y -qq install libgtk2.0-0 libgtk-3-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb net-tools chromium && \
    apt-get -y clean && apt-get -y purge && rm -rf /var/lib/apt/lists/* && rm -Rf /tmp/pear

USER www

ENV PATH=$PATH:/home/www/.yarn/bin
RUN \
    yarn global add cypress@^4.2 && \
    yarn cache clean && \
    symfony -v && \
    chromium --version && \
    cypress --version

USER root
