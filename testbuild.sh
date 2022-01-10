
# reset env
export FROM_IMAGE=
export PHP_VERSION=
export PHP_EXTENSIONS=

# override
export DOCKER_PREFIX=nlzet/php
export PHP_VERSION=8.1

./run.sh build cli stage1 "--no-cache"
./run.sh build fpm stage2
./run.sh build ci stage3
docker run -w /var/www/php/test/ -v /tmp/composercache/:/home/www/.composer/cache/ -v $(pwd)/:/var/www -i ${DOCKER_PREFIX}:${PHP_VERSION}-cli composer update -W
./run.sh testxdebug
./run.sh push cli
./run.sh push fpm
./run.sh push ci
