# Docker PHP images
This repository serves as an easy way to configure and build docker PHP images (powered by [docker-php-extension-installer]([https://github.com/mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer))) with some extra libraries and tools:
* `locales`: install extra locales with locale-gen to support internal PHP date localization
* `optipng  pngcrush  pngquant, jpegoptim, gifsicle, jpegtran` install system tools for image optimization, (usage example [[https://github.com/psliwa/image-optimizer](https://github.com/psliwa/image-optimizer)])
* `mhsendmail` for local email debugging with mailhog (installed but disabled by default, , can be enabled with ini configuration (cli argument or mounted .ini file)
* `wkhtmltopdf wkhtmltoimage` for html to pdf/image conversion
* `nodejs / yarn` (added at stage2, see below)
* `chromium, symfony server, global node packages, ...` (at stage3, see below)
* `xdebug` is installed but disabled by default, can be enabled with ini configuration (cli argument or mounted .ini file)

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
| [nlzet/php:8.1-cli](https://hub.docker.com/r/nlzet/php/tags) | stage1 |
| [nlzet/php:8.1-fpm](https://hub.docker.com/r/nlzet/php/tags) | stage2 |
| [nlzet/php:8.1-ci](https://hub.docker.com/r/nlzet/php/tags) | stage3 |

All tags are built weekly (on Thursday) based on the official php `major.minor` php tags (e.g. `php:7.4-fpm`). The following defaults are applied to these builds:

| Option | Value |
|--|--|
| PHP_EXTENSIONS | `amqp bcmath bz2 exif gd gettext gmp igbinary imagick intl mcrypt mongodb mysqli pcntl pdo_mysql pdo_pgsql redis sockets soap xdebug xmlrpc xsl zip` |
| FROM_IMAGE | `php:${PHP_VERSION}-fpm` |
  
# Building your own image  

You can build your own image with your own set of php extensions and configuration options.
Available options and information are described below:

## Configuration options:  
  
### Build options

| Variable | Description | Default | 
|--|--|--|
|PHP_VERSION|Choose the PHP version, you can select major, minor and patch version. E.g. `7`, `7.4` or `7.4.10`| |
|PHP_EXTENSIONS|Choose the PHP extensions to install, select supported extensions from [https://github.com/mlocati/docker-php-extension-installer#supported-php-extensions](https://github.com/mlocati/docker-php-extension-installer#supported-php-extensions)| |
|LOCALEGEN|String containing the locales to install, seperated by `\n`|`en_US.UTF-8 UTF-8\nnl_NL.UTF-8 UTF-8\nnl_BE.UTF-8 UTF-8\nfr_FR.UTF-8 UTF-8\nde_DE.UTF-8 UTF-8`|
|UID| www user id | `1000` |
|GID| www group id | `1000` |

### Auto-generated options

| Variable | Description | Default | 
|--|--|--|
|FROM_IMAGE|Tag from the official PHP base images to base on (choose a `-fpm` suffix to support it in all multistage builds) | `php:${PHP_VERSION}-fpm`|

### Multistage build targets

| Docker stage | Description | Entrypoint |
|--|--|--| 
| builder | build-/download external dependencies from source like image optim libraries or mhsendmail | default |
| composer | composer multistage to export composer binary | default |
| extensions | base image, builds requested PHP extensions and configures image optim packages | default |
| stage1 | cli image with entrypoint php bin and install locales | php bin |
| stage2 | fpm image with entrypoint fpm and add nodejs and yarn | fpm bin |
| stage3 | ci image for CI e2e testing | php bin |
  
### Example build:

    docker build \
	    --build-arg PHP_EXTENSIONS="gd xdebug" \
	    --build-arg PHP_VERSION=7.4 \
	    --target stage1 \
	    php/ \
	    --pull

# Using the image

## CLI

### Check PHP configuration:

    # get version
    docker run -it nlzet/php:7.3-cli php -v
    
    # list configured modules
    docker run -it nlzet/php:7.3-cli php -m
    
    # list configured ini files
    docker run -it nlzet/php:7.3-cli php --ini
    
### Enable Xdebug:
    
    # command line argument
    docker run -it nlzet/php:7.3-cli php -d zend_extension=xdebug.so -v
    
    # or with a mounted .ini file, containing "zend_extension=xdebug.so"
    docker run -v $(pwd)/xdebug.ini:/usr/local/etc/php/conf.d/99-enable-xdebug.ini -it nlzet/php:7.3-cli php -v
    
## FPM:
    
    # start fpm container, wich will directly start php-fpm
    docker run -it nlzet/php:7.3-fpm    

## Docker pull all:

    versions=(7.3 7.4 8.1 8.2)
    tags=(ci fpm cli)

    for version in $versions
    do
        for tag in $tags
        do
            echo "pulling nlzet/php:$version-$tag"
            docker pull nlzet/php:$version-$tag
        done
    done

# Check composer / php versions

    versions=(7.3 7.4 8.1 8.2)
    tags=(ci fpm cli)

    for version in $versions
    do
        for tag in $tags
        do
            echo "checking versions for nlzet/php:$version-$tag"
            cmd='$(php -v | head -n 1) - $(composer --version)'
            docker run -it nlzet/php:$version-$tag bash -c "echo $(echo $cmd)"
        done
    done
