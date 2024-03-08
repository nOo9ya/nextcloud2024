#!/bin/bash

read -p "DB root password : " DBROOTPASS
if [ -z "$DBROOTPASS" ]; then
    echo "DB root password exist!!"
    exit 9
fi

read -p "DB user id : " USERID
if [ -z "$USERID" ]; then
    echo "DB user id exist!!"
    exit 9
fi

read -p "DB user password : " USERPW
if [ -z "$USERPW" ]; then
    echo "DB user password exist!!"
    exit 9
fi

read -p "DB name : " DBNAME
if [ -z "$DBNAME" ]; then
    echo "DB name exist!!"
    exit 9
fi


echo "--------------------------------------------------------------"
echo "---------------- add Database user ---------------------------"
echo "--------------------------------------------------------------"

mysql -uroot -p$DBROOTPASS -e "CREATE DATABASE ${DBNAME}
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;"
mysql -uroot -p$DBROOTPASS -e "CREATE USER '${USERID}'@'%' IDENTIFIED BY '${USERPW}'"
mysql -uroot -p$DBROOTPASS -e "GRANT USAGE ON *.* TO '${USERID}'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0"
mysql -uroot -p$DBROOTPASS -e "GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${USERID}'@'%'"