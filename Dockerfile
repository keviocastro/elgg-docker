FROM php:5.6-apache
COPY . /elgg-docker/
COPY docker_config/php.ini /usr/local/etc/php/

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        netcat \
        mysql-client \
        locales \
        libicu-dev

# Elgg requirements
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd
RUN docker-php-ext-install pdo pdo_mysql mysql
RUN docker-php-ext-install mbstring

WORKDIR /var/www/html/

#Configs apache
RUN a2enmod rewrite

#Set time zone in server
ENV TIMEZONE=${TIMEZONE:-"America/Sao_Paulo"}
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
#Set time zone in PHP
RUN sed -i "s#{{timezone}}#$TIMEZONE#g" /usr/local/etc/php/php.ini

#Set default locale in PHP
#See http://php.net/setlocale
ENV PHP_DEFAULT_LOCALE=${PHP_DEFAULT_LOCALE:-"pt_BR.UTF-8"}
RUN docker-php-ext-install intl
RUN sed -i -e "s/# $PHP_DEFAULT_LOCALE UTF-8/$PHP_DEFAULT_LOCALE UTF-8/" /etc/locale.gen && \
    echo "LANG=\"$PHP_DEFAULT_LOCALE\"">/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales
RUN sed -i "s#{{locale}}#$PHP_DEFAULT_LOCALE#g" /usr/local/etc/php/php.ini

# set defaults or env vars for Elgg and MySQL
# MySQL
ENV MYSQL_USER=${MYSQL_USER:-"root"}
ENV MYSQL_PASS=${MYSQL_PASS:-"root-pass"}
ENV MYSQL_PORT=${MYSQL_PORT:-"3306"}

# required for installation
ENV ELGG_DB_HOST=${ELGG_DB_HOST:-"mysql"}
ENV ELGG_DB_USER=$MYSQL_USER
ENV ELGG_DB_PASS=$MYSQL_PASS
ENV ELGG_DB_NAME=${ELGG_DB_NAME:-"elgg"}

ENV ELGG_SITE_NAME=${ELGG_SITE_NAME:-"Elgg Site"}
ENV ELGG_DATA_ROOT=${ELGG_DATA_ROOT:-"/media/elgg/"}
ENV ELGG_WWW_ROOT=${ELGG_WWW_ROOT:-"http://localhost:8000"}

# admin user setup
ENV ELGG_DISPLAY_NAME=${ELGG_DISPLAY_NAME:-"Admin"}
ENV ELGG_EMAIL=${ELGG_EMAIL:-"admin@myelgg.org"}
ENV ELGG_USERNAME=${ELGG_USERNAME:-"admin"}
ENV ELGG_PASSWORD=${ELGG_PASSWORD:-"admin-pass"}

# optional for installation
ENV ELGG_DB_PREFIX=${ELGG_DB_PREFIX:-"elgg_"}
ENV ELGG_PATH=${ELGG_PATH:-"/var/www/html/"}
# 2 is ACCESS_PUBLIC
ENV ELGG_SITE_ACCESS=${ELGG_SITE_ACCESS:-"2"}

# If true, enable xdebug and vim editor
ENV DEBUG=${DEBUG:-"false"}

# If true, should be informed of the file name that contains the dump to be restored in the database.
# The file name must be the address for the directory /var/www/html/. Example: /var/www/html/deploy/dump-initial-data.sql
ENV MYSQL_DATABASE_INITIAL_DATA=${MYSQL_DATABASE_INITIAL_DATA:-"false"}

RUN chmod +x /elgg-docker/elgg-install.sh
RUN chmod +x /elgg-docker/environment-setup.sh
RUN mkdir $ELGG_DATA_ROOT
RUN chown -R www-data:www-data $ELGG_DATA_ROOT
RUN chmod 770 -R $ELGG_DATA_ROOT

RUN /elgg-docker/environment-setup.sh
