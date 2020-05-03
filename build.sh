#!/usr/bin/env bash

CACHED=--no-cache
# CACHED=

docker rmi nlzet/php56-cli --force && \
docker rmi nlzet/php56-fpm --force && \
docker rmi nlzet/php73-cli --force && \
docker rmi nlzet/php73-fpm --force && \
docker rmi nlzet/php73-ci --force && \
docker rmi nlzet/php74-cli --force && \
docker rmi nlzet/php74-fpm --force && \
docker rmi nlzet/php74-ci --force && \

docker build --pull -t nlzet/php56-cli php/php56-cli ${CACHED} && \
docker push nlzet/php56-cli && \
docker build --pull -t nlzet/php56-fpm php/php56-fpm ${CACHED} && \
docker push nlzet/php56-fpm && \
docker build --pull -t nlzet/php73-cli php/php73-cli ${CACHED} && \
docker push nlzet/php73-cli && \
docker build --pull -t nlzet/php73-fpm php/php73-fpm ${CACHED} && \
docker push nlzet/php73-fpm && \
docker build --pull -t nlzet/php73-ci php/php73-ci ${CACHED} && \
docker push nlzet/php73-ci && \
docker build --pull -t nlzet/php74-cli php/php74-cli ${CACHED} && \
docker push nlzet/php74-cli && \
docker build --pull -t nlzet/php74-fpm php/php74-fpm ${CACHED} && \
docker push nlzet/php74-fpm && \
docker build --pull -t nlzet/php74-ci php/php74-ci ${CACHED} && \
docker push nlzet/php74-ci
