#!/bin/bash

# Add latest php version repository
add-apt-repository ppa:ondrej/php

# install php
read -p "Install php version? [defalt: 8.2]: " PHP_VERSION

if [ -z "$PHP_VERSION" ]; then
    PHP_VERSION=8.2
else
    PHP_VERSION=$PHP_VERSION
if

read -p "Install mariadb version? [defalt: 10.11]: " MARIADB_VERSION
read -p "DB root password: " DB_ROOT_PASSWORD

if [ -z "$MARIADB_VERSION" ]; then
    MARIADB_VERSION=10.11
else
    MARIADB_VERSION=$MARIADB_VERSION
if


echo "---------------- Installing php version : $PHP_VERSION"
apt-get install -y php$PHP_VERSION-fpm \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-zip \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-gmp \
    php$PHP_VERSION-mysql \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-common \
    php$PHP_VERSION-pdo \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-json \
    php$PHP_VERSION-redis \
    php$PHP_VERSION-opcache \
    php$PHP_VERSION-readline 
    # php$PHP_VERSION-xsl
    # php$PHP_VERSION-xdebug

sed -i 's/;emergency_restart_threshold = 0/emergency_restart_threshold = 10/g' /etc/php/$PHP_VERSION/fpm/php-fpm.conf && \
sed -i 's/;emergency_restart_interval = 0/emergency_restart_interval = 1m/g' /etc/php/$PHP_VERSION/fpm/php-fpm.conf && \



echo "---------------- Installing mariadb version : $MARIADB_VERSION"
# Add latest mariaDB version repository
apt-get -y install apt-transport-https curl && \
curl -o /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc 'https://mariadb.org/mariadb_release_signing_key.asc' && \
sh -c "echo 'deb https://mirrors.xtom.jp/mariadb/repo/10.11/ubuntu jammy main' >> /etc/apt/sources.list" && \
apt-get update


debconf-set-selections <<< "mariadb-server-$MARIADB_VERSION mysql-server/root_password password $DB_ROOT_PASSWORD"
debconf-set-selections <<< "mariadb-server-$MARIADB_VERSION mysql-server/root_password_again password $DB_ROOT_PASSWORD"

apt-get -y install mariadb-server mariadb-client




echo "---------------- Installing redis install : $MARIADB_VERSION"
apt-get -y install redis-server

systemctl enable redis-server


service php$PHP_VERSION-fpm start
service mariadb start
service redis-server start

