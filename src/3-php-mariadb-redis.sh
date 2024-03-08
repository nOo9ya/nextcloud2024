#!/bin/bash

echo "--------------------------------------------------------------"
echo "---------------- Installing PHP + MariaDB + Redis"
echo "--------------------------------------------------------------"

# install php
read -p "Install php version? [defalt: 8.3]: " PHP_VERSION

if [[ -z "$PHP_VERSION" ]]; then
    PHP_VERSION=8.3
else
    PHP_VERSION=$PHP_VERSION
fi

read -p "Install mariadb version? [defalt: 10.11]: " MARIADB_VERSION
read -p "DB root password: " DB_ROOT_PASSWORD

if [ -z "$MARIADB_VERSION" ]; then
    MARIADB_VERSION=10.11
else
    MARIADB_VERSION=$MARIADB_VERSION
fi

# Add latest php version repository
add-apt-repository ppa:ondrej/php -y
# 도커 컨테이너가 아니라면 sudo를 붙여야 한다
# sudo add-apt-repository ppa:ondrej/php
apt-get update

echo "--------------------------------------------------------------"
echo "---------------- Installing php version : $PHP_VERSION"
echo "--------------------------------------------------------------"
apt-get install -y php$PHP_VERSION-fpm \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-xmlrpc \
    php$PHP_VERSION-zip \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-gmp \
    php$PHP_VERSION-mysql \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-common \
    php$PHP_VERSION-pdo \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-redis \
    php$PHP_VERSION-opcache \
    php$PHP_VERSION-memcache \
    php$PHP_VERSION-readline \
    php$PHP_VERSION-imagick \
    php$PHP_VERSION-dev \
    php$PHP_VERSION-imap 
    # php$PHP_VERSION-xsl
    # php$PHP_VERSION-xdebug

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "---------------- Installing PHP ------------------------------"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "---------------- configure PHP-FPM /etc/php/$PHP_VERSION/fpm/php-fpm.ini"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
sed -i 's/;emergency_restart_threshold = 0/emergency_restart_threshold = 10/g' /etc/php/$PHP_VERSION/fpm/php-fpm.conf
sed -i 's/;emergency_restart_interval = 0/emergency_restart_interval = 1m/g' /etc/php/$PHP_VERSION/fpm/php-fpm.conf

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "---------------- configure PHP-POOL /etc/php/$PHP_VERSION/fpm/pool.d/www.conf"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
sed -i 's/pm.max_children = 5/pm.max_children = 20/g' /etc/php/$PHP_VERSION/fpm/pool.d/www.conf
sed -i 's/pm.start_servers = 2/pm.start_servers = 8/g' /etc/php/$PHP_VERSION/fpm/pool.d/www.conf
sed -i 's/pm.min_spare_servers = 1/pm.min_spare_servers = 4/g' /etc/php/$PHP_VERSION/fpm/pool.d/www.conf
sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 12/g' /etc/php/$PHP_VERSION/fpm/pool.d/www.conf

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "---------------- configure PHP.INI /etc/php/$PHP_VERSION/fpm/php.ini"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 128M/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /etc/php/$PHP_VERSION/fpm/php.ini



echo "--------------------------------------------------------------"
echo "---------------- Installing mariadb version : $MARIADB_VERSION"
echo "--------------------------------------------------------------"
# Add latest mariaDB version repository
apt-get -y install apt-transport-https curl && \
curl -o /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc 'https://mariadb.org/mariadb_release_signing_key.asc' && \
sh -c "echo 'deb https://mirrors.xtom.jp/mariadb/repo/10.11/ubuntu jammy main' >> /etc/apt/sources.list" && \
apt-get update


debconf-set-selections <<< "mariadb-server-$MARIADB_VERSION mysql-server/root_password password $DB_ROOT_PASSWORD"
debconf-set-selections <<< "mariadb-server-$MARIADB_VERSION mysql-server/root_password_again password $DB_ROOT_PASSWORD"

apt-get -y install mariadb-server mariadb-client

systemctl enable mariadb

service mariadb start


echo "--------------------------------------------------------------------"
echo "---------------- make mariadb config : /etc/mysql/conf.d/mariadb.cnf"
echo "--------------------------------------------------------------------"
echo "[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4

[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-name-resolve
skip-external-locking

## MariaDB 스케줄러
event-scheduler = OFF
sysdate-is-now

back_log = 100
max_connections = 300
max_connect_errors = 999999
# max_connections에 비례해서 사용
thread_cache_size = 50
table_open_cache = 400
wait_timeout = 6000

max_allowed_packet = 32M
max_heap_table_size = 32M
tmp_table_size = 512K

sort_buffer_size = 128K
join_buffer_size = 128K
read_buffer_size = 128K
read_rnd_buffer_size = 128K

query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 2M

group_concat_max_len = 1024

# 마스터 MariaDB 서버에서 레코드 기반 복제를 사용할 때는 READ-COMMITTED 사용 가능
# 복제에 참여하지 않는 MariaDB 서버에서는 READ-COMMITTED 사용 가능
# 그 외에는 반드시 REPEATABLE-READ 로 사용
transaction-isolation = REPEATABLE-READ

# InnoDB 기본 옵션
# InnoDB를 사용하지 않는다면 innodb_buffer_pool_size를 최소화하거나
# InnoDB 스토리지 엔젠을 기동하지 않도록 설정
innodb_buffer_pool_size = 1G

# MyISAM 옵션
# InnoDB를 사용하지 않고 MyISAM만 사용한다면 key_buffer_size를 4GB까지 설정
key_buffer_size = 32M

# 로깅 옵션
slow-query-log = 1
long_query_time = 1

# 복제 옵션
binlog_cache_size = 128K
max_binlog_size = 512M
expire_logs_days = 14
log-bin-trust-function-creators = 1
sync_binlog = 1

lower_case_table_names = 1
query_cache_min_res_unit = 2k
sql_mode = NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION

[mysqldump]
default-character-set=utf8mb4
max_allowed_packet = 32M
" > /etc/mysql/conf.d/mariadb.cnf

service mariadb restart


echo "--------------------------------------------------------------"
echo "---------------- Installing redis install : $MARIADB_VERSION"
echo "--------------------------------------------------------------"
apt-get -y install redis-server

systemctl enable redis-server


service php$PHP_VERSION-fpm start
service mariadb restart
service redis-server start

echo "PHP + MariaDB + Redis install is completed!!!"
echo "------------ service status -----------------"
service --status-all