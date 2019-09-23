#!/usr/bin/env bash

#CACHED=--no-cache
CACHED=

# cleanup existing images
docker rmi nlzet/php56-cli --force && \
docker rmi nlzet/php56-fpm --force && \
docker rmi nlzet/php73-cli --force && \
docker rmi nlzet/php73-fpm --force

# Build and push
docker build --pull -t nlzet/php56-cli php/php56-cli && \
docker push nlzet/php56-cli && \
docker build --pull -t nlzet/php56-fpm php/php56-fpm ${CACHED} && \
docker push nlzet/php56-fpm && \
docker build --pull -t nlzet/php73-cli php/php73-cli ${CACHED}
docker push nlzet/php73-cli && \
docker build --pull -t nlzet/php73-fpm php/php73-fpm ${CACHED} && \
docker push nlzet/php73-fpm
