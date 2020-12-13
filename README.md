# Docker PHP images
This repository serves as an easy way to configure and build docker PHP images (powered by [docker-php-extension-installer]([https://github.com/mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer))) with some extra libraries and tools:
* locales: install extra locales with locale-gen to support internal PHP date localization
* install system tools for image optimization, (usage example [[https://github.com/psliwa/image-optimizer](https://github.com/psliwa/image-optimizer)]): `optipng  pngcrush  pngquant, jpegoptim, gifsicle, jpegtran`
* `mhsendmail` for local email debugging
* `wkhtmltopdf` for pdf generation
* `nodejs / yarn` (only in stage2, see below)
* `chromium, symfony server, global node packages, ...` (only in stage3, see below)

# Available tags

## Default build options

| Tag | Stage |
|--|--|
| [nlzet/php:7.3-cli](https://hub.docker.com/r/nlzet/php/tags) | stage1 |
| [nlzet/php:7.3-fpm](https://hub.docker.com/r/nlzet/php/tags) | stage2 |
| [nlzet/php:7.3-ci](https://hub.docker.com/r/nlzet/php/tags) | stage3 |
| [nlzet/php:7.4-cli](https://hub.docker.com/r/nlzet/php/tags) | stage1 |
| [nlzet/php:7.4-fpm](https://hub.docker.com/r/nlzet/php/tags) | stage2 |
| [nlzet/php:7.4-ci](https://hub.docker.com/r/nlzet/php/tags) | stage3 |
| [nlzet/php:8.0-cli](https://hub.docker.com/r/nlzet/php/tags) | stage1 |
| [nlzet/php:8.0-fpm](https://hub.docker.com/r/nlzet/php/tags) | stage2 |
| [nlzet/php:8.0-ci](https://hub.docker.com/r/nlzet/php/tags) | stage3 |

All tags are built and pushed weekly (on Thursday), these default options are applied to all built tags:

| Option | Value |
|--|--|
| PHP_EXTENSIONS | `amqp bcmath bz2 exif gd gettext gmp igbinary imagick intl mcrypt mongodb mysqli pdo_mysql pdo_pgsql redis sockets soap xdebug xmlrpc xsl zip` (PHP 8 limits to the currently supported extensions) |
| FROM_IMAGE | `php:${PHP_VERSION}-fpm` |
  
# Building your own image  
  
## Configuration options:  
  
### Build options

| Variable | Explanation |  
|--|--|
|PHP_VERSION|Choose the PHP version, you can select major, minor and patch version. E.g. `7` or `7.4.10`|
|PHP_EXTENSIONS|Choose the PHP extensions to install, select supported extensions from [https://github.com/mlocati/docker-php-extension-installer#supported-php-extensions](https://github.com/mlocati/docker-php-extension-installer#supported-php-extensions)|

### Extra build options

| Variable | Explanation | Default | 
|--|--|--|
|FROM_IMAGE|Choose a tag from the official PHP base images. You should choose a `-fpm` to support it in all multistage builds | `php:${PHP_VERSION}-fpm`|
|LOCALEGEN|String containing the locales to install, seperated by `\n`|`en_US.UTF-8 UTF-8\nnl_NL.UTF-8 UTF-8`|

### Multistage build targets

| Docker stage | Description |
|--|--|
| builder | build-/download external dependencies from source like image optim libraries or mhsendmail |
| composer | composer multistage to export composer binary |
| extensions | base image, builds requested PHP extensions and configures image optim packages |
| stage1 | configure cli container, install locales |
| stage2 | configure fpm image, add nodejs and yarn |
| stage3 | configure ci image, add extras like global node packages and install/configure ymfony webserver |
  
### Example build:

    export PHP_VERSION=7.4
    export PHP_EXTENSIONS="gd xdebug"  
    
    docker build \
	    --build-arg PHP_EXTENSIONS="${PHP_EXTENSIONS}" \
	    --build-arg FROM_IMAGE=${FROM_IMAGE} \
	    --target stage1 \
	    php/ \
	    --pull
