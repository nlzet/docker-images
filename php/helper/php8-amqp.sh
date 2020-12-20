#!/usr/bin/env sh

PHP_MAJOR_VERSION=$(echo $PHP_VERSION | cut -d "." -f1)

stringInList() {
	for stringInList_listItem in $2; do
		if test "$1" = "$stringInList_listItem"; then
			return 0
		fi
	done
	return 1
}

anyStringInList() {
	for anyStringInList_item in $1; do
		if stringInList "$anyStringInList_item" "$2"; then
			return 0
		fi
	done
	return 1
}

removeStringFromList() {
	removeStringFromList_result=''
	for removeStringFromList_listItem in $2; do
		if test "$1" != "$removeStringFromList_listItem"; then
			if test -z "$removeStringFromList_result"; then
				removeStringFromList_result="$removeStringFromList_listItem"
			else
				removeStringFromList_result="$removeStringFromList_result $removeStringFromList_listItem"
			fi
		fi
	done
	printf '%s' "$removeStringFromList_result"
}

build_amqp8 () {
  if [ "$INSTALL_AMQP8" -eq "1" ]; then
    echo "> amqp8.build: build for PHP $PHP_MAJOR_VERSION"

    docker-php-source extract
    apt update && apt -y install --no-install-recommends git librabbitmq-dev \
    git clone --depth 1 https://github.com/php-amqp/php-amqp.git /usr/src/php/ext/amqp \
    cd /usr/src/php/ext/amqp && git submodule update --init \
    docker-php-ext-install amqp
    rm -rf /usr/src/php/ext/amqp /tmp/* /var/tmp/* /var/lib/{apt,dpkg,cache,log}/
    docker-php-source delete
  else
    echo "> amqp8.build: skipping"
  fi
}

configure_env_vars() {
  if stringInList "amqp" "$PHP_EXTENSIONS"; then
    if [ "$PHP_MAJOR_VERSION" -eq "8" ]; then
      PHP_EXTENSIONS="$(removeStringFromList "amqp" "$PHP_EXTENSIONS")"
      echo "export PHP_EXTENSIONS=\"${PHP_EXTENSIONS}\""
      echo "export INSTALL_AMQP8=1"
    else
      echo "export INSTALL_AMQP8=0"
    fi    
  else
    echo "export INSTALL_AMQP8=0"
  fi
}

case $1 in
  env)
    configure_env_vars
    ;;

  build)
    build_amqp8
    ;;
esac
